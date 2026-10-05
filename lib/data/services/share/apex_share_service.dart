// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/domain/models/note.dart';

/// خدمة فحص وجود Apex Transfer والمشاركة عبره
///
/// تعتمد على MethodChannel الموجود في MainActivity.kt
/// (isPackageInstalled + openApexWithFile)
class ApexShareService {
  static const _channel = MethodChannel('com.apexflow.app.sinan/widget');
  static const apexPackage = 'com.apexflow.tools.transfer';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$apexPackage';

  /// هل Apex Transfer مثبت على الجهاز؟
  ///
  /// يعمل على Android فقط. على Desktop يرجع false دائماً.
  static Future<bool> isInstalled() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        {'package': apexPackage},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// إرسال ملاحظة إلى Apex Transfer كملف .sinan — نسخة طبق الأصل بنفس صيغة
  /// النسخ الاحتياطية. يرمي [PlatformException] (`NOT_INSTALLED`) إن لم يكن مثبتاً.
  static Future<void> sendNote(Note note) async {
    final tmp = await getTemporaryDirectory();
    final safeTitle = (note.title.isEmpty ? 'note' : note.title)
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .trim();
    final filePath = '${tmp.path}/$safeTitle.sinan';
    await File(filePath).writeAsString(jsonEncode(NoteMapper.toMap(note)));
    await openFileInApex(filePath);
  }

  /// فتح ملف .sinan في Apex Transfer
  ///
  /// يُرجع true إذا نجح، أو يرمي استثناء إذا لم يكن Apex مثبتاً.
  static Future<bool> openFileInApex(String filePath) async {
    final result = await _channel.invokeMethod<bool>(
      'openApexWithFile',
      {'path': filePath},
    );
    return result ?? false;
  }
}

// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/data/repositories/backup_repository.dart';

export 'package:sinan_note/data/repositories/backup_repository.dart'
    show BackupContents;

/// أوامر النسخ الاحتياطي للواجهات: اختيار ملف، قراءته، دمجه أو استبداله،
/// وتصدير القاعدة أو مشاركتها.
class BackupViewModel {
  BackupViewModel({required BackupRepository backups}) : _backups = backups;

  final BackupRepository _backups;

  Future<String?> pickFile() =>
      FlutterFileDialog.pickFile(params: const OpenFileDialogParams());

  /// يرمي `ValidationException` لملف ليس نسخة يقرؤها هذا الإصدار.
  Future<BackupContents> read(String path) => _backups.read(path);

  Future<int> localNotesCount() => _backups.localNotesCount();

  /// يرمي `VaultLockedException` إن احتاج الملف تشفير ملاحظات والخزنة مقفلة.
  Future<int> merge(BackupContents contents) => _backups.merge(contents);

  Future<void> replace(BackupContents contents) => _backups.replace(contents);

  Future<String> exportTo(String directory) => _backups.exportTo(directory);

  /// يحفظ لقطة عبر نافذة النظام. يُرجع false إن ألغى المستخدم.
  Future<bool> saveWithDialog() async {
    final path = await _backups.exportTo((await getTemporaryDirectory()).path);
    final saved = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: path,
        mimeTypesFilter: const ['application/octet-stream'],
      ),
    );
    return saved != null;
  }

  Future<void> share({required String subject, required String text}) async {
    final path = await _backups.exportTo((await getTemporaryDirectory()).path);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/octet-stream')],
      subject: subject,
      text: text,
    );
  }
}

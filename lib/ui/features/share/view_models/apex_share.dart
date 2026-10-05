// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/data/services/share/apex_share_service.dart';
import 'package:sinan_note/domain/models/note.dart';

/// المشاركة عبر تطبيق Apex File Share.
class ApexShare {
  Future<bool> isInstalled() => ApexShareService.isInstalled();
  Future<void> send(Note note) => ApexShareService.sendNote(note);
  String get storeUrl => ApexShareService.playStoreUrl;
}

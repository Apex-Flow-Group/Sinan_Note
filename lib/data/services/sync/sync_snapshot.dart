// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/domain/errors.dart' show ValidationException;
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/sync/tombstones.dart';

/// حالة جهاز كما تُرفع إلى السحابة.
///
/// الصيغة 3 تضيف `tombstones` فقط؛ المفاتيح القديمة باقية فيقرأ الملفَّ
/// الإصدارُ السابق. يُقرأ أيضاً ملف الإصدارات 1 (قائمة ملاحظات) و2.
class SyncSnapshot {
  const SyncSnapshot({
    required this.notes,
    required this.categories,
    this.tombstones = const Tombstones(),
    this.hideProFromHome,
  });

  final List<Note> notes;

  /// رقم التصنيف في هذه اللقطة ← اسمه، بالترتيب.
  final Map<int, String> categories;
  final Tombstones tombstones;
  final bool? hideProFromHome;

  Map<String, Object?> toJson(DateTime now) => {
        'version': '3',
        'created_at': now.toIso8601String(),
        'notes': [for (final n in notes) NoteMapper.toMap(n)],
        'categories': [
          for (final (i, MapEntry(:key, :value)) in categories.entries.indexed)
            {'id': key, 'name': value, 'sortOrder': i},
        ],
        // الإصدار 2 يقرأ هذا المفتاح؛ أرقامه محلية لا معنى لها بين الأجهزة
        'deleted_ids': const <String, int>{},
        'tombstones': tombstones.toJson(),
        'settings': {
          if (hideProFromHome != null) 'hide_pro_from_home': hideProFromHome,
        },
      };

  /// يرمي [ValidationException] لمحتوى ليس لقطة.
  factory SyncSnapshot.fromJson(Object? json) {
    try {
      if (json is List) {
        return SyncSnapshot(notes: _notes(json), categories: const {});
      }
      if (json is! Map) throw const FormatException('not a snapshot');
      final settings = json['settings'];
      final hidePro =
          settings is Map ? settings['hide_pro_from_home'] as bool? : null;
      final rawCategories = [...?(json['categories'] as List?)]
        ..sort((a, b) => ((a as Map)['sortOrder'] as int? ?? 0)
            .compareTo((b as Map)['sortOrder'] as int? ?? 0));
      return SyncSnapshot(
        notes: _notes(json['notes'] as List? ?? const []),
        categories: {
          for (final c in rawCategories.cast<Map>())
            c['id'] as int: c['name'] as String,
        },
        tombstones: json['tombstones'] is Map
            ? Tombstones.fromJson(
                (json['tombstones'] as Map).cast<String, Object?>())
            : const Tombstones(),
        hideProFromHome: hidePro,
      );
    } on Object catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException('Unreadable sync snapshot', e);
    }
  }

  static List<Note> _notes(List<dynamic> raw) => [
        for (final m in raw.cast<Map>())
          NoteMapper.fromMap(m.cast<String, Object?>()),
      ];
}

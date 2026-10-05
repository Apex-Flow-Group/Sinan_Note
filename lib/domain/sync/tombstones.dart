// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/categories.dart';

/// ما حُذف ومتى، لتنشره المزامنة لبقية الأجهزة: الملاحظات بالـ uuid
/// والتصنيفات باسمها (المعرّف الرقمي يختلف من جهاز لآخر).
///
/// الحذف ينتشر بالشاهد وحده — غياب ملاحظة عن جهاز لا يعني حذفها.
class Tombstones {
  const Tombstones({
    this.notes = const {},
    this.categories = const {},
    this.revivedCategories = const {},
  });

  final Map<String, DateTime> notes;

  /// اسم التصنيف (بصيغة المقارنة) ← وقت حذفه.
  final Map<String, DateTime> categories;

  /// اسم التصنيف ← وقت إنشائه من جديد بعد حذف. الأحدث من الحدثين يحكم.
  final Map<String, DateTime> revivedCategories;

  /// مدة بقاء الشاهد. جهاز غاب عن المزامنة أطول منها قد يعيد ما حُذف.
  static const lifetime = Duration(days: 90);

  bool get isEmpty =>
      notes.isEmpty && categories.isEmpty && revivedCategories.isEmpty;

  /// الاتحاد، بأحدث وقت لكل مفتاح.
  Tombstones union(Tombstones other) => Tombstones(
        notes: _latest(notes, other.notes),
        categories: _latest(categories, other.categories),
        revivedCategories: _latest(revivedCategories, other.revivedCategories),
      );

  Tombstones withNotes(Iterable<String> uuids, DateTime at) =>
      union(Tombstones(notes: {for (final u in uuids) u: at}));

  Tombstones withCategory(String name, DateTime at) =>
      union(Tombstones(categories: {CategoryPolicy.sameNameKey(name): at}));

  Tombstones withRevivedCategory(String name, DateTime at) => union(
      Tombstones(revivedCategories: {CategoryPolicy.sameNameKey(name): at}));

  /// يُسقط ما هو أقدم من [lifetime].
  Tombstones prune(DateTime now) {
    final cutoff = now.subtract(lifetime);
    Map<String, DateTime> recent(Map<String, DateTime> m) => {
          for (final e in m.entries)
            if (e.value.isAfter(cutoff)) e.key: e.value,
        };
    return Tombstones(
      notes: recent(notes),
      categories: recent(categories),
      revivedCategories: recent(revivedCategories),
    );
  }

  /// حُذفت بعد آخر تعديل لها؟ تعديل لاحق للحذف يعيدها.
  bool deletes(String uuid, DateTime updatedAt) {
    final at = notes[uuid];
    return at != null && at.isAfter(updatedAt);
  }

  /// التصنيف محذوف ولم يُنشأ بعد حذفه؟
  bool deletesCategory(String name) {
    final key = CategoryPolicy.sameNameKey(name);
    final deleted = categories[key];
    if (deleted == null) return false;
    final revived = revivedCategories[key];
    return revived == null || deleted.isAfter(revived);
  }

  Map<String, Object> toJson() => {
        'notes': _encode(notes),
        'categories': _encode(categories),
        'revived_categories': _encode(revivedCategories),
      };

  factory Tombstones.fromJson(Map<String, Object?> json) => Tombstones(
        notes: _decode(json['notes']),
        categories: _decode(json['categories']),
        revivedCategories: _decode(json['revived_categories']),
      );

  static Map<String, DateTime> _latest(
      Map<String, DateTime> a, Map<String, DateTime> b) {
    final out = {...a};
    b.forEach((key, at) {
      final mine = out[key];
      if (mine == null || at.isAfter(mine)) out[key] = at;
    });
    return out;
  }

  static Map<String, int> _encode(Map<String, DateTime> m) =>
      m.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch));

  static Map<String, DateTime> _decode(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in raw.entries)
        if (value is int)
          '$key': DateTime.fromMillisecondsSinceEpoch(value, isUtc: true),
    };
  }
}

// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:sinan_note/data/services/key_value_store.dart';
import 'package:sinan_note/domain/sync/tombstones.dart';

/// سجل الحذف الذي تنشره المزامنة: يكتب فيه المستودعان، وتقرؤه المزامنة
/// وتستبدله باتحاد الجهازين.
abstract interface class DeletionLog {
  Future<void> notesDeleted(List<String> uuids);
  Future<void> categoryDeleted(String name);
  Future<void> categoryCreated(String name);
}

/// [Tombstones] كـ JSON في [KeyValueStore].
class TombstoneStore implements DeletionLog {
  TombstoneStore(this._store, {DateTime Function()? clock})
      : _now = clock ?? (() => DateTime.now().toUtc());

  static const _key = 'sync_tombstones';

  final KeyValueStore _store;
  final DateTime Function() _now;

  Future<Tombstones> read() async {
    final raw = await _store.getString(_key);
    if (raw == null) return const Tombstones();
    try {
      return Tombstones.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const Tombstones();
    }
  }

  Future<void> write(Tombstones tombstones) async {
    final pruned = tombstones.prune(_now());
    await _store.setString(_key, jsonEncode(pruned.toJson()));
  }

  @override
  Future<void> notesDeleted(List<String> uuids) async {
    if (uuids.isEmpty) return;
    await write((await read()).withNotes(uuids, _now()));
  }

  @override
  Future<void> categoryDeleted(String name) async =>
      write((await read()).withCategory(name, _now()));

  @override
  Future<void> categoryCreated(String name) async {
    final current = await read();
    if (!current.deletesCategory(name)) return;
    await write(current.withRevivedCategory(name, _now()));
  }
}

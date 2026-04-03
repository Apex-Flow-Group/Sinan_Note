// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class NoteCategory {
  Id id = Isar.autoIncrement;

  late String name;

  @Index()
  late int sortOrder;

  NoteCategory({this.id = Isar.autoIncrement, required this.name, this.sortOrder = 0});
}

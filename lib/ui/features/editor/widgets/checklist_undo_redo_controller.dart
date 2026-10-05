// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


class ChecklistUndoRedoController {
  final VoidCallback undo;
  final VoidCallback redo;
  final bool canUndo;
  final bool canRedo;

  ChecklistUndoRedoController({
    required this.undo,
    required this.redo,
    required this.canUndo,
    required this.canRedo,
  });
}


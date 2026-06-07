// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';


/// Holds all state variables for the note editor
class EditorState {
  // Controllers
  final TextEditingController contentController;
  final CodeController codeController;
  final UndoHistoryController undoController;

  // UI State
  Color backgroundColor;
  Color textColor;
  double fontSize;
  TextAlign textAlign;
  TextDirection textDirection;

  // Note State
  String? customTitle;
  String? checklistTitle;
  int? savedNoteId;
  bool isDirty;
  bool hasContent;
  bool isAuthenticated;
  bool isSaving;

  // Security
  String? notePassword;

  // Smart Features
  String? detectedLanguage;
  bool isLanguageManuallySelected;
  DateTime? reminderDateTime;
  String? recurrenceRule;

  EditorState({
    required this.contentController,
    required this.codeController,
    required this.undoController,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.fontSize = 18.0,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.rtl,
    this.customTitle,
    this.checklistTitle,
    this.savedNoteId,
    this.isDirty = false,
    this.hasContent = false,
    this.isAuthenticated = false,
    this.isSaving = false,
    this.notePassword,
    this.detectedLanguage,
    this.isLanguageManuallySelected = false,
    this.reminderDateTime,
    this.recurrenceRule,
  });

  void dispose() {
    // Clear text buffers before disposing
    contentController.clear();
    contentController.dispose();
    codeController.clear();
    codeController.dispose();
    undoController.dispose();
  }
}


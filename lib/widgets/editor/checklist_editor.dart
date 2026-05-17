// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/core/constants/app_text_styles.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:apex_note/widgets/editor/checklist_item_widget.dart';
import 'package:apex_note/widgets/editor/checklist_undo_redo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChecklistEditor extends StatefulWidget {
  final String initialContent;
  final String? initialTitle; // ← العنوان الأصلي للنوتة كـ fallback
  final Function(String jsonContent) onChanged;
  final Color backgroundColor;
  final VoidCallback? onUndoRedoChanged;
  final Function(ChecklistUndoRedoController)? onUndoRedoControllerCreated;
  final bool readOnly;

  const ChecklistEditor({
    super.key,
    required this.initialContent,
    required this.onChanged,
    required this.backgroundColor,
    this.initialTitle,
    this.onUndoRedoChanged,
    this.onUndoRedoControllerCreated,
    this.readOnly = false,
  });

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  List<ChecklistItem> _items = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, VoidCallback> _listeners = {};
  final TextEditingController _titleController = TextEditingController();

  // Undo/Redo support
  final List<String> _history = [];
  int _historyIndex = -1;
  bool _isUndoRedoAction = false;
  bool _lastCanUndo = false;
  bool _lastCanRedo = false;

  TextDirection _titleDirection = TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _parseContent();
    _titleDirection = TextDirectionUtils.getDirection(_titleController.text);
    _titleController.addListener(_notifyParent);
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final newDir = TextDirectionUtils.getDirection(_titleController.text);
    if (newDir != _titleDirection) {
      setState(() => _titleDirection = newDir);
    }
  }

  void _parseContent() {
    if (widget.initialContent.trim().isEmpty) {
      // 🎯 SMART SOLUTION: Add auto item for UX, but mark it as "ghost"
      _addNewItem(isGhostItem: true);
      return;
    }

    try {
      final dynamic decoded = jsonDecode(widget.initialContent);

      if (decoded is Map<String, dynamic>) {
        _titleController.text = decoded['title'] ?? '';
        if (decoded['items'] != null && decoded['items'] is List) {
          _items = (decoded['items'] as List)
              .map((e) => ChecklistItem.fromJson(e))
              .toList();
        }
      } else if (decoded is List) {
        // ── صيغة قديمة: array بدون title ──────────────────────────────
        // نستخدم initialTitle (note.title) كـ fallback إذا كان موجوداً
        if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
          _titleController.text = widget.initialTitle!;
        }
        _items = decoded
            .whereType<Map>()
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Fallback: Parse as plain text
      if (widget.initialContent.trim().isNotEmpty) {
        final lines = widget.initialContent
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        _items = lines.map((line) {
          return ChecklistItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                line.hashCode.toString(),
            text: line.replaceAll(RegExp(r'^-\s*\[.\]\s*'), '').trim(),
          );
        }).toList();
      }
    }

    // Only add item if we have existing content but no parsed items
    if (_items.isEmpty && widget.initialContent.trim().isNotEmpty) {
      _addNewItem();
    }

    for (var item in _items) {
      _initializeController(item);
    }

    // حفظ snapshot أولي في الـ history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyParent();
    });
  }

  void _initializeController(ChecklistItem item) {
    _controllers[item.id] = TextEditingController(text: item.text);
    _focusNodes[item.id] = FocusNode();

    // Store listener reference so we can remove it later
    void listener() {
      item.text = _controllers[item.id]!.text;
      _notifyParent();
    }

    _listeners[item.id] = listener;
    _controllers[item.id]!.addListener(listener);

    _focusNodes[item.id]!.addListener(() {
      if (_focusNodes[item.id]!.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = _focusNodes[item.id]!.context;
          if (context != null && context.mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.5,
            );
          }
        });
      }
    });
  }

  void _addNewItem(
      {int? insertIndex, bool autoFocus = false, bool isGhostItem = false}) {
    final newItem = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isGhost: isGhostItem, // Mark as ghost for smart filtering
    );

    setState(() {
      if (insertIndex != null) {
        _items.insert(insertIndex, newItem);
      } else {
        _items.add(newItem);
      }
      _initializeController(newItem);
    });

    if (autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[newItem.id]?.requestFocus();
      });
    }

    // Only notify parent if not a ghost item or if ghost item gets content
    if (!isGhostItem) {
      _notifyParent();
    }
  }

  void _deleteItem(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1 || _items.length == 1) return;

    // حفظ نسخة للتراجع
    final deletedItem = _items[index];
    final deletedText = _controllers[id]?.text ?? '';

    setState(() {
      _items.removeAt(index);
      if (_controllers.containsKey(id) && _listeners.containsKey(id)) {
        _controllers[id]!.removeListener(_listeners[id]!);
      }
      _controllers[id]?.dispose();
      _focusNodes[id]?.dispose();
      _controllers.remove(id);
      _focusNodes.remove(id);
      _listeners.remove(id);
    });

    _notifyParent();

    // Snackbar دوار مع زر تراجع
    final ctx = context;
    if (!ctx.mounted) return;
    final l10n = AppLocalizations.of(ctx)!;
    final restoredItem = ChecklistItem(
      id: deletedItem.id,
      text: deletedText,
      isDone: deletedItem.isDone,
    );
    UnifiedNotificationService().showWithUndo(
      context: ctx,
      message: deletedText.isEmpty
          ? l10n.itemDeleted
          : '"$deletedText" ${l10n.deleted}',
      actionKey: 'checklist_delete_${deletedItem.id}',
      type: NotificationType.info,
      onExecute: () {},
      onUndo: () {
        if (!mounted) return;
        setState(() {
          final insertAt = index.clamp(0, _items.length);
          _items.insert(insertAt, restoredItem);
          _initializeController(restoredItem);
          _controllers[restoredItem.id]?.text = deletedText;
        });
        _notifyParent();
      },
      undoLabel: l10n.undo,
    );
  }

  void _toggleDone(ChecklistItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      item.isDone = !item.isDone;
    });
    _notifyParent();
  }

  void sortItems(String type) {
    setState(() {
      if (type == 'doneBottom') {
        _items.sort((a, b) => a.isDone == b.isDone ? 0 : (a.isDone ? 1 : -1));
      } else if (type == 'doneTop') {
        _items.sort((a, b) => a.isDone == b.isDone ? 0 : (a.isDone ? -1 : 1));
      } else if (type == 'original') {
        _items.sort((a, b) => a.id.toString().compareTo(b.id.toString()));
      }
    });
    _notifyParent();
  }

  void _showSortSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        title: l10n.sort,
        titleIcon: Icons.swap_vert_rounded,
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.arrow_downward_rounded, color: Colors.blue),
              title: Text(l10n.sortDoneToBottom),
              onTap: () {
                Navigator.pop(context);
                sortItems('doneBottom');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.arrow_upward_rounded, color: Colors.green),
              title: Text(l10n.sortDoneToTop),
              onTap: () {
                Navigator.pop(context);
                sortItems('doneTop');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.restore_rounded, color: Colors.grey),
              title: Text(l10n.sortOriginal),
              onTap: () {
                Navigator.pop(context);
                sortItems('original');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _notifyParent() {
    if (!mounted) return;

    // 🛡️ Force sync all controllers to models
    for (var item in _items) {
      if (_controllers.containsKey(item.id)) {
        item.text = _controllers[item.id]!.text;
        if (item.isGhost && item.text.trim().isNotEmpty) {
          item.isGhost = false;
        }
      }
    }

    _recalcProgress();

    // 🎯 Filter empty ghost items
    final realItems = _items
        .where((item) => !item.isGhost || item.text.trim().isNotEmpty)
        .toList();

    // ✅ VALIDATION: Prevent saving completely empty checklists
    final title = _titleController.text.trim();
    final hasContent = title.isNotEmpty ||
        realItems.any((item) => item.text.trim().isNotEmpty);

    if (!hasContent && !_isUndoRedoAction) {
      // Empty checklist - don't save garbage, but don't block undo/redo
      widget.onChanged(jsonEncode({'title': '', 'items': []}));
      return;
    }

    final data = {
      'title': title,
      'items': realItems.map((e) => e.toJson()).toList(),
    };
    final jsonData = jsonEncode(data);

    // Save to history for undo/redo
    if (!_isUndoRedoAction) {
      _history.removeRange(_historyIndex + 1, _history.length);
      _history.add(jsonData);
      _historyIndex = _history.length - 1;
      // MEMORY FIX: Reduced from 50 to 20 to limit memory usage
      if (_history.length > 20) {
        _history.removeAt(0);
        _historyIndex--;
      }
    }

    widget.onChanged(jsonData);

    // 🔧 FIX: أطلق onUndoRedoChanged فقط إذا تغيرت الحالة فعلاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateUndoRedoController();
        // لا نُطلق onUndoRedoChanged إلا إذا تغيرت حالة undo/redo
        final newCanUndo = canUndo;
        final newCanRedo = canRedo;
        if (newCanUndo != _lastCanUndo || newCanRedo != _lastCanRedo) {
          _lastCanUndo = newCanUndo;
          _lastCanRedo = newCanRedo;
          widget.onUndoRedoChanged?.call();
        }
      }
    });
  }

  void _updateUndoRedoController() {
    widget.onUndoRedoControllerCreated?.call(
      ChecklistUndoRedoController(
        undo: undo,
        redo: redo,
        canUndo: canUndo,
        canRedo: canRedo,
      ),
    );
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _restoreState(_history[_historyIndex]);
      widget.onUndoRedoChanged?.call();
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _restoreState(_history[_historyIndex]);
      widget.onUndoRedoChanged?.call();
    }
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void _restoreState(String jsonData) {
    _isUndoRedoAction = true;
    try {
      final decoded = jsonDecode(jsonData);
      _titleController.text = decoded['title'] ?? '';

      // Clear old items
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      for (var node in _focusNodes.values) {
        node.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();

      // Restore items
      _items = (decoded['items'] as List)
          .map((e) => ChecklistItem.fromJson(e))
          .toList();

      // إذا لم تكن هناك items، أضف ghost item للـ UX
      if (_items.isEmpty) {
        _addNewItem(isGhostItem: true);
      } else {
        for (var item in _items) {
          _initializeController(item);
        }
      }

      _recalcProgress();
      setState(() {});
    } finally {
      _isUndoRedoAction = false;
    }
  }

  double _progress = 0.0;
  double _lastProgress = 0.0;

  void _recalcProgress() {
    _lastProgress = _progress;
    if (_items.isEmpty) {
      _progress = 0.0;
    } else {
      final done = _items.where((e) => e.isDone).length;
      _progress = done / _items.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isLightColor = widget.backgroundColor.computeLuminance() > 0.5;
    final Color textColor = isLightColor ? Colors.black87 : Colors.white;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      textDirection: _titleDirection,
                      textAlign: _titleDirection == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        fontSize: AppFontSize.noteTitle,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.checklistTitle,
                        hintStyle:
                            TextStyle(color: textColor.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.swap_vert_rounded,
                        color: textColor.withValues(alpha: 0.6)),
                    tooltip: l10n.sort,
                    onPressed: () => _showSortSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_items.isNotEmpty)
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '${_items.where((e) => e.isDone).length} / ${_items.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: _lastProgress, end: _progress),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) {
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: textColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              value >= 1.0 ? Colors.green : Colors.blue,
                            ),
                            minHeight: 6,
                          );
                        },
                        onEnd: () {
                          _lastProgress = _progress;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverReorderableList(
          itemBuilder: (context, index) {
            final item = _items[index];
            final row = _buildItemRow(item, index, textColor);
            return widget.readOnly
                ? KeyedSubtree(
                    key: ValueKey(item.id),
                    child: row,
                  )
                : RepaintBoundary(
                    key: ValueKey(item.id),
                    child: row,
                  );
          },
          itemCount: _items.length,
          onReorder: widget.readOnly
              ? (_, __) {}
              : (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                  });
                  _notifyParent();
                },
          proxyDecorator: widget.readOnly
              ? null
              : (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    shadowColor: Colors.black26,
                    elevation: 10,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
        ),
        SliverPadding(padding: EdgeInsets.only(bottom: keyboardHeight)),
        // زر إضافة item واحد في أسفل القائمة
        if (!widget.readOnly)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(12, 4, 12, keyboardHeight > 0 ? 8 : 24),
              child: TextButton.icon(
                onPressed: () => _addNewItem(autoFocus: true),
                icon: Icon(Icons.add_rounded,
                    size: 18, color: textColor.withValues(alpha: 0.5)),
                label: Text(
                  l10n.addItem,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemRow(ChecklistItem item, int index, Color textColor) {
    final controller = _controllers[item.id]!;
    final focusNode = _focusNodes[item.id]!;

    final itemWidget = ChecklistItemWidget(
      key: ValueKey(item.id),
      item: item,
      index: index,
      controller: controller,
      focusNode: focusNode,
      textColor: textColor,
      backgroundColor: widget.backgroundColor,
      showControls: !widget.readOnly,
      readOnly: widget.readOnly,
      onToggleDone: widget.readOnly ? null : () => _toggleDone(item),
      onTextChanged: widget.readOnly ? null : (_) {},
      onSubmitted: widget.readOnly
          ? null
          : () => _addNewItem(insertIndex: index + 1, autoFocus: true),
    );

    if (widget.readOnly || _items.length <= 1) return itemWidget;

    // Dismissible للحذف بالسحب يميناً
    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
      ),
      confirmDismiss: (_) async {
        // لا نحذف إذا كان آخر item
        return _items.length > 1;
      },
      onDismissed: (_) => _deleteItem(item.id),
      child: itemWidget,
    );
  }

  String get checklistTitle {
    if (_titleController.text.trim().isNotEmpty) {
      return _titleController.text.trim();
    }
    if (_items.isNotEmpty && _items.first.text.isNotEmpty) {
      return _items.first.text;
    }
    return 'Checklist'; // Safe fallback without context access
  }

  @override
  void dispose() {
    // 🛑 CRITICAL: Remove title listeners BEFORE clearing
    _titleController.removeListener(_notifyParent);
    _titleController.removeListener(_onTitleChanged);
    _titleController.clear();
    _titleController.dispose();

    // 🛑 CRITICAL: Remove ALL item listeners BEFORE clearing to prevent empty save
    for (var item in _items) {
      if (_controllers.containsKey(item.id) &&
          _listeners.containsKey(item.id)) {
        _controllers[item.id]!.removeListener(_listeners[item.id]!);
      }
    }
    _listeners.clear();

    // Now safe to clear and dispose
    for (var controller in _controllers.values) {
      controller.clear();
      controller.dispose();
    }
    _controllers.clear();

    // Dispose focus nodes
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();

    // CRITICAL: Clear undo/redo history to free memory
    _history.clear();
    _historyIndex = -1;

    // Clear items list
    _items.clear();

    super.dispose();
  }
}

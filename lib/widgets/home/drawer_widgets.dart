// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/widgets/home/categories_panel.dart';

class CategoriesPanelWrapper extends StatefulWidget {
  final CatPanelMode mode;
  final bool isAdding;
  final VoidCallback onAddDone;

  const CategoriesPanelWrapper({
    super.key,
    required this.mode,
    required this.isAdding,
    required this.onAddDone,
  });

  @override
  State<CategoriesPanelWrapper> createState() => _CategoriesPanelWrapperState();
}

class _CategoriesPanelWrapperState extends State<CategoriesPanelWrapper> {
  final _scrollController = ScrollController();

  static const double _tileHeight = 52.0;
  static const int _maxVisible = 6;

  @override
  void didUpdateWidget(CategoriesPanelWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAdding && !oldWidget.isAdding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoriesProvider>();
    final totalItems =
        provider.categories.length + 2 + (widget.isAdding ? 1 : 0);
    final needsScroll = totalItems > _maxVisible;
    const maxHeight = _tileHeight * _maxVisible;

    final panel = CategoriesPanel(
      mode: widget.mode,
      isAdding: widget.isAdding,
      onAddDone: widget.onAddDone,
    );

    if (!needsScroll) return panel;

    return SizedBox(
      height: maxHeight,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        radius: const Radius.circular(4),
        thickness: 3,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: panel,
        ),
      ),
    );
  }
}

class DrawerModeBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const DrawerModeBtn({
    super.key,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? color : scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}


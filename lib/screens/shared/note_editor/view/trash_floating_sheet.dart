// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

/// Sheet عائم في الأسفل لملاحظات المهملات — يبدأ بـ handle فقط ويتمدد عند السحب
class TrashFloatingSheet extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  const TrashFloatingSheet({
    super.key,
    required this.fadeAnimation,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  @override
  State<TrashFloatingSheet> createState() => _TrashFloatingSheetState();
}

class _TrashFloatingSheetState extends State<TrashFloatingSheet>
    with SingleTickerProviderStateMixin {
  static const double _peekH = 56.0;
  static const double _fullH = 56.0 + 56.0 + 1.0 + 56.0 + 16.0;

  late final AnimationController _anim;
  late final Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightAnim = Tween<double>(begin: _peekH, end: _fullH).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = -d.primaryDelta! / (_fullH - _peekH);
    _anim.value = (_anim.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    if (d.primaryVelocity != null && d.primaryVelocity! < -300) {
      _anim.forward();
    } else if (d.primaryVelocity != null && d.primaryVelocity! > 300) {
      _anim.reverse();
    } else if (_anim.value > 0.5) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  void _toggle() {
    if (_anim.value > 0.5) {
      _anim.reverse();
    } else {
      _anim.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: AnimatedBuilder(
        animation: _heightAnim,
        builder: (context, _) {
          final height = _heightAnim.value + bottomPad;
          final openRatio = _anim.value;

          return GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            onTap: _toggle,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: isDark ? scheme.surfaceContainerLow : scheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'اسحب للأعلى'
                              : 'Swipe up',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Opacity(
                      opacity: openRatio,
                      child: IgnorePointer(
                        ignoring: openRatio < 0.5,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.restore_rounded,
                                    color: Colors.green, size: 22),
                              ),
                              title: Text(l10n.restore,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              onTap: widget.onRestore,
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_forever_rounded,
                                    color: Colors.red, size: 22),
                              ),
                              title: Text(
                                l10n.permanentDelete,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600),
                              ),
                              onTap: widget.onPermanentDelete,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


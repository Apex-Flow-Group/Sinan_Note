// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// زر نسخ الكود مع animation علامة صح — بدون SnackBar
class CopyCodeButton extends StatefulWidget {
  final String code;
  final String label;

  const CopyCodeButton({
    super.key,
    required this.code,
    required this.label,
  });

  @override
  State<CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<CopyCodeButton>
    with SingleTickerProviderStateMixin {
  bool _copied = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onCopy() async {
    if (_copied) return;
    await Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    _controller.forward().then((_) => _controller.reverse());
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _copied ? Colors.green : Theme.of(context).colorScheme.primary;

    return ScaleTransition(
      scale: _scaleAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.07),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _onCopy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    key: ValueKey(_copied),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Text(
                    _copied ? '' : widget.label,
                    key: ValueKey(_copied),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


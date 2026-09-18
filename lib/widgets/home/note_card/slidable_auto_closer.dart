// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SlidableAutoCloser extends StatefulWidget {
  final ValueNotifier<int> closerNotifier;
  final Widget child;

  const SlidableAutoCloser({
    super.key,
    required this.closerNotifier,
    required this.child,
  });

  @override
  State<SlidableAutoCloser> createState() => _SlidableAutoCloserState();
}

class _SlidableAutoCloserState extends State<SlidableAutoCloser> {
  @override
  void initState() {
    super.initState();
    widget.closerNotifier.addListener(_onGlobalTouch);
  }

  @override
  void dispose() {
    widget.closerNotifier.removeListener(_onGlobalTouch);
    super.dispose();
  }

  void _onGlobalTouch() {
    final controller = Slidable.of(context);
    // كل لمسة تصل لكل بطاقة مرئية. إغلاق المغلق أصلاً يشغّل أنيميشن 200ms
    // في كل بطاقة عند بداية كل سحبة تمرير.
    if (controller == null || controller.ratio == 0) return;
    controller.close();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

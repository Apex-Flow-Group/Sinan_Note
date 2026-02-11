// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Widget لعرض أيقونة مع نص بدلاً من الإيموجي
class IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? textStyle;
  final double spacing;

  const IconText({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.iconSize = 16,
    this.textStyle,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        SizedBox(width: spacing),
        Expanded(
          child: Text(text, style: textStyle),
        ),
      ],
    );
  }
}

/// Helper لاستبدال الإيموجي الشائعة
class EmojiIcons {
  static const warning = Icons.warning_amber_rounded;
  static const lock = Icons.lock_rounded;
  static const key = Icons.key_rounded;
  static const download = Icons.download_rounded;
  static const fire = Icons.local_fire_department_rounded;
  static const check = Icons.check_circle_rounded;
  static const refresh = Icons.refresh_rounded;
  static const target = Icons.adjust_rounded;
  static const cloud = Icons.cloud_rounded;
  static const stop = Icons.stop_circle_rounded;
  static const shield = Icons.shield_rounded;
  static const lightbulb = Icons.lightbulb_rounded;
  static const bolt = Icons.bolt_rounded;
  static const upload = Icons.upload_rounded;
  static const document = Icons.description_rounded;
}

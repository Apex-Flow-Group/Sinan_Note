// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/core/utils/adaptive_color.dart';
import 'package:sinan_note/models/note.dart';

/// عزل سبب ثقل سكرول الرئيسية.
///
/// Masonry مفعّل من الخطوة 0 (ليس محل الاختبار).
/// غيّر [step] فقط، ثم **Hot Restart**، ثم افلِنغ بسرعة.
///
/// 0 Masonry + صناديق لون بارتفاع متغيّر — بلا نص/ظل/سحب
/// 1 عنوان — انظر [titleProbe]
/// 2 معاينة 4 أسطر
/// 3 ظل BoxShadow
/// 4 ClipRRect
/// 5 GestureDetector
/// 6 Listener
/// 7 البطاقة الحقيقية كاملة
class GridPerfProbe {
  static const int step = 7;

  /// داخل الخطوة 1 فقط:
  /// 0 نفس الكلمة "Title" لكل الكروت (عزل تخطيط النص الفريد)
  /// 1 عنوان حقيقي مقصوص 20 حرف بدون ellipsis
  /// 2 عنوان كامل + ellipsis (ثبت أنه ثقيل)
  static const int titleProbe = 2;

  static const int maxStep = 7;

  static bool get isActive => step < maxStep;
  static bool get showTitle => step >= 1;
  static bool get showContent => step >= 2;
  static bool get showShadow => step >= 3;
  static bool get showClip => step >= 4;
  static bool get showGestures => step >= 5;
  static bool get showListener => step >= 6;
  static bool get useMasonry => true;
  static bool get useRealCards => step >= 7;

  static double get cacheExtent => isActive ? 250 : 1500;
  static double get tileExtent => showContent ? 140 : 72;
}

class ProbeNoteTile extends StatelessWidget {
  final Note note;

  const ProbeNoteTile({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final index = note.colorIndex.clamp(0, AppColorPalette.palette.length - 1);
    final color = AppColorPalette.palette[index].getColor(brightness);

    Widget child = GridPerfProbe.useMasonry &&
            !GridPerfProbe.showTitle &&
            !GridPerfProbe.showContent
        ? SizedBox(height: 56 + ((note.id ?? 0) % 5) * 20)
        : GridPerfProbe.useMasonry
            ? const SizedBox.shrink()
            : const SizedBox.expand();
    if (GridPerfProbe.showTitle || GridPerfProbe.showContent) {
      child = Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: GridPerfProbe.useMasonry
              ? MainAxisSize.min
              : MainAxisSize.max,
          children: [
            if (GridPerfProbe.showTitle) _titleText(note),
            if (GridPerfProbe.showContent) ...[
              const SizedBox(height: 8),
              Text(
                note.previewPlain,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      );
    }

    Widget box = ColoredBox(color: color, child: child);

    if (GridPerfProbe.showShadow || GridPerfProbe.showClip) {
      box = Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              GridPerfProbe.showClip ? BorderRadius.circular(16) : null,
          boxShadow: GridPerfProbe.showShadow
              ? const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior:
            GridPerfProbe.showClip ? Clip.hardEdge : Clip.none,
        child: child,
      );
    }

    if (GridPerfProbe.showListener) {
      box = Listener(
        onPointerDown: (_) {},
        child: box,
      );
    }

    if (GridPerfProbe.showGestures) {
      box = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        onLongPress: () {},
        child: box,
      );
    }

    return box;
  }

  Widget _titleText(Note note) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    switch (GridPerfProbe.titleProbe) {
      case 0:
        return const Text('Title', maxLines: 1, style: style);
      case 1:
        final raw = note.title.isEmpty ? 'Untitled' : note.title;
        final short = raw.length <= 20 ? raw : raw.substring(0, 20);
        return Text(short, maxLines: 1, overflow: TextOverflow.clip, style: style);
      default:
        final raw = note.title.isEmpty ? 'Untitled' : note.title;
        return Text(
          raw,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
    }
  }
}

class ProbeBanner extends StatelessWidget {
  const ProbeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE53935),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Text(
        'PERF PROBE ${GridPerfProbe.step}/${GridPerfProbe.maxStep} titleProbe=${GridPerfProbe.titleProbe} + masonry — Hot Restart',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

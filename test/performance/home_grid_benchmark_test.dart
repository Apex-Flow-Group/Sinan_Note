// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// قياس أداء تخطيط الشبكة الرئيسية:
//   [BEFORE] SliverMasonryGrid — ارتفاع غير محدود لكل بطاقة (الوضع الحالي)
//   [AFTER]  SliverGrid ثابت  — ارتفاع موحّد لكل الخلايا (الهدف)
//
// الهدف: توثيق الفارق قبل تطبيق التغيير على الإنتاج. لا يفشل الاختبار على
// أي قيمة — الأرقام للمقارنة فقط.
//
// تشغيل: flutter test test/performance/home_grid_benchmark_test.dart -v

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── ثوابت ─────────────────────────────────────────────────────────────────
  const kCount = 100; // بطاقات تملأ عدة شاشات
  const kFlings = 8; // عدد السحبات لمحاكاة التمرير السريع
  const kFlingVelocity = 1400.0; // سرعة السحب بـ px/s
  const kFlingOffset = Offset(0, -450); // مسافة كل سحبة

  // أبعاد هاتف Android متوسط (pixel units)
  const kPhysicalSize = Size(1080, 2340);
  const kDevicePixelRatio = 3.0;

  // ── ارتفاعات متغيرة تُحاكي ارتفاعات بطاقات الملاحظات الفعلية ──────────────
  const heights = [80.0, 130.0, 100.0, 165.0, 92.0, 148.0, 115.0, 122.0];

  // ── بطاقة مبسّطة — بلا providers، تعكس التكلفة البصرية للبطاقة الحقيقية ──
  Widget simCard(int index) {
    return Container(
      height: heights[index % heights.length],
      decoration: BoxDecoration(
        color: Colors.primaries[index % Colors.primaries.length]
            .withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 14, width: 120, color: Colors.black38),
            const SizedBox(height: 8),
            Container(
                height: 10, width: double.infinity, color: Colors.black26),
            const SizedBox(height: 4),
            Container(
              height: 10,
              width: index % 3 == 0 ? 80 : double.infinity,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  // ── إعداد حجم الشاشة ────────────────────────────────────────────────────────
  void setPhoneScreen(WidgetTester t) {
    t.view.physicalSize = kPhysicalSize;
    t.view.devicePixelRatio = kDevicePixelRatio;
  }

  // ── [BEFORE] SliverMasonryGrid — الحالة الراهنة ───────────────────────────

  Widget masonryScaffold() => MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(4),
                sliver: SliverMasonryGrid(
                  gridDelegate:
                      const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => simCard(i),
                    childCount: kCount,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── [AFTER] SliverGrid ثابت — الهدف ─────────────────────────────────────────

  Widget fixedGridScaffold() => MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(4),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.85, // ارتفاع ≈ عرض × 1.18
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => simCard(i),
                    childCount: kCount,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── مساعد قياس التمرير ───────────────────────────────────────────────────────
  Future<int> measureScroll(WidgetTester t) async {
    final sw = Stopwatch()..start();
    for (var i = 0; i < kFlings; i++) {
      await t.fling(
          find.byType(CustomScrollView), kFlingOffset, kFlingVelocity);
      await t.pumpAndSettle();
    }
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BEFORE — SliverMasonryGrid
  // ════════════════════════════════════════════════════════════════════════════

  testWidgets('[BEFORE — MASONRY] initial build $kCount cards', (t) async {
    setPhoneScreen(t);
    addTearDown(t.view.resetPhysicalSize);

    final sw = Stopwatch()..start();
    await t.pumpWidget(masonryScaffold());
    await t.pump();
    sw.stop();

    debugPrint(
      '\n'
      '══════════════════════════════════════════\n'
      '[GRID BEFORE — MASONRY] initial build\n'
      '  cards  : $kCount\n'
      '  time   : ${sw.elapsedMilliseconds}ms\n'
      '══════════════════════════════════════════',
    );
  });

  testWidgets('[BEFORE — MASONRY] scroll $kFlings flings', (t) async {
    setPhoneScreen(t);
    addTearDown(t.view.resetPhysicalSize);

    await t.pumpWidget(masonryScaffold());
    await t.pump();

    final total = await measureScroll(t);

    debugPrint(
      '\n'
      '══════════════════════════════════════════\n'
      '[GRID BEFORE — MASONRY] scroll\n'
      '  flings : $kFlings × ${kFlingOffset.dy.abs().toInt()}px\n'
      '  total  : ${total}ms\n'
      '  avg    : ${total ~/ kFlings}ms/fling\n'
      '══════════════════════════════════════════',
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // AFTER — SliverGrid ثابت
  // ════════════════════════════════════════════════════════════════════════════

  testWidgets('[AFTER — FIXED] initial build $kCount cards', (t) async {
    setPhoneScreen(t);
    addTearDown(t.view.resetPhysicalSize);

    final sw = Stopwatch()..start();
    await t.pumpWidget(fixedGridScaffold());
    await t.pump();
    sw.stop();

    debugPrint(
      '\n'
      '══════════════════════════════════════════\n'
      '[GRID AFTER — FIXED] initial build\n'
      '  cards  : $kCount\n'
      '  time   : ${sw.elapsedMilliseconds}ms\n'
      '══════════════════════════════════════════',
    );
  });

  testWidgets('[AFTER — FIXED] scroll $kFlings flings', (t) async {
    setPhoneScreen(t);
    addTearDown(t.view.resetPhysicalSize);

    await t.pumpWidget(fixedGridScaffold());
    await t.pump();

    final total = await measureScroll(t);

    debugPrint(
      '\n'
      '══════════════════════════════════════════\n'
      '[GRID AFTER — FIXED] scroll\n'
      '  flings : $kFlings × ${kFlingOffset.dy.abs().toInt()}px\n'
      '  total  : ${total}ms\n'
      '  avg    : ${total ~/ kFlings}ms/fling\n'
      '══════════════════════════════════════════',
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // ملخص مقارن
  // ════════════════════════════════════════════════════════════════════════════

  testWidgets('[SUMMARY] masonry vs fixed — side by side comparison',
      (t) async {
    setPhoneScreen(t);
    addTearDown(t.view.resetPhysicalSize);

    // ── masonry ─────────────────────────────────────────────────────────────
    final mBuildSw = Stopwatch()..start();
    await t.pumpWidget(masonryScaffold());
    await t.pump();
    mBuildSw.stop();
    final mScrollMs = await measureScroll(t);

    // ── fixed ────────────────────────────────────────────────────────────────
    final fBuildSw = Stopwatch()..start();
    await t.pumpWidget(fixedGridScaffold());
    await t.pump();
    fBuildSw.stop();
    final fScrollMs = await measureScroll(t);

    // ── طباعة المقارنة ───────────────────────────────────────────────────────
    final buildDiff =
        mBuildSw.elapsedMilliseconds - fBuildSw.elapsedMilliseconds;
    final scrollDiff = mScrollMs - fScrollMs;

    debugPrint(
      '\n'
      '╔══════════════════════════════════════════════════════╗\n'
      '║         HOME GRID BENCHMARK — SUMMARY                ║\n'
      '╠══════════════════════════════════════════════════════╣\n'
      '║  Cards: $kCount | Flings: $kFlings | Screen: ${kPhysicalSize.width.toInt()}×${kPhysicalSize.height.toInt()} @${kDevicePixelRatio.toInt()}x\n'
      '╠══════════════════════════════════════════════════════╣\n'
      '║  INITIAL BUILD                                       ║\n'
      '║    Masonry  : ${mBuildSw.elapsedMilliseconds.toString().padLeft(5)}ms                           ║\n'
      '║    Fixed    : ${fBuildSw.elapsedMilliseconds.toString().padLeft(5)}ms                           ║\n'
      '║    Diff     : ${buildDiff > 0 ? '+' : ''}${buildDiff}ms (${buildDiff > 0 ? 'fixed faster' : 'masonry faster'})\n'
      '╠══════════════════════════════════════════════════════╣\n'
      '║  SCROLL ($kFlings flings)                                ║\n'
      '║    Masonry  : ${mScrollMs.toString().padLeft(5)}ms total | ${(mScrollMs ~/ kFlings).toString().padLeft(3)}ms/fling        ║\n'
      '║    Fixed    : ${fScrollMs.toString().padLeft(5)}ms total | ${(fScrollMs ~/ kFlings).toString().padLeft(3)}ms/fling        ║\n'
      '║    Diff     : ${scrollDiff > 0 ? '+' : ''}${scrollDiff}ms (${scrollDiff > 0 ? 'fixed faster' : 'masonry faster'})\n'
      '╚══════════════════════════════════════════════════════╝',
    );
  });
}

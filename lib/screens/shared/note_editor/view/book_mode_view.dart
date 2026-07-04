// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/core/utils/quill_migration.dart';
import 'package:sinan_note/core/utils/text_direction_utils.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/editor/markdown_viewer.dart';

// ─── عدد أحرف الصفحة الافتراضي ──────────────────────────────────
const _charsPerPage = 900;

// ─── إيجاد نقطة قطع آمنة لا تكسر الكلمة ─────────────────────────
/// يرجع index القطع بأقرب مسافة أو \n قبل [limit]
int _safeBreak(String text, int limit) {
  if (limit >= text.length) return text.length;
  // ابحث للخلف عن مسافة أو سطر جديد
  for (int i = limit; i > 0; i--) {
    final c = text[i - 1];
    if (c == ' ' || c == '\n' || c == '\u200B') return i;
  }
  // لا يوجد مسافة — اقطع عند الحد مباشرة
  return limit;
}

// ─── تقسيم Delta لصفحات (حرف-محدود مع كسر الكلمة) ───────────────
List<Delta> _splitDeltaIntoPages(Delta delta,
    {int charsPerPage = _charsPerPage}) {
  // استخرج النص الكامل مع تتبع موضع كل op
  final allOps = delta.toList().where((op) => op.isInsert).toList();

  // ابنِ النص الكامل كـ plain string لتحديد نقاط القطع
  final fullText = StringBuffer();
  for (final op in allOps) {
    if (op.data is String) fullText.write(op.data as String);
  }
  final text = fullText.toString();
  if (text.isEmpty) return [Delta()..insert('\n')];

  // حدد نقاط القطع
  final breakPoints = <int>[0];
  int pos = 0;
  while (pos < text.length) {
    int next = pos + charsPerPage;
    if (next >= text.length) {
      break;
    }
    // اقطع عند مسافة أو \n آمنة
    final bp = _safeBreak(text, next);
    breakPoints.add(bp);
    pos = bp;
  }
  breakPoints.add(text.length);

  // أنشئ Delta لكل صفحة
  final pages = <Delta>[];
  for (int p = 0; p < breakPoints.length - 1; p++) {
    final start = breakPoints[p];
    final end = breakPoints[p + 1];
    if (start >= end) continue;

    final page = Delta();
    int charPos = 0;

    for (final op in allOps) {
      if (op.data is! String) {
        // embed — أضفه للصفحة الأولى فقط
        if (p == 0) page.insert(op.data, op.attributes);
        continue;
      }
      final opText = op.data as String;
      final opStart = charPos;
      final opEnd = charPos + opText.length;
      charPos = opEnd;

      if (opEnd <= start || opStart >= end) continue;

      final sliceStart = (start - opStart).clamp(0, opText.length);
      final sliceEnd = (end - opStart).clamp(0, opText.length);
      final slice = opText.substring(sliceStart, sliceEnd);
      if (slice.isNotEmpty) {
        page.insert(slice, op.attributes);
      }
    }

    // تأكد أن الصفحة تنتهي بـ \n
    if (page.isNotEmpty) {
      final lastOp = page.toList().last;
      if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
        page.insert('\n');
      }
      pages.add(page);
    }
  }

  return pages.isEmpty ? [Delta()..insert('\n')] : pages;
}

// ─── تقسيم نص عادي لصفحات (حرف-محدود مع كسر الكلمة) ─────────────
List<String> _splitPlainIntoPages(String text,
    {int charsPerPage = _charsPerPage}) {
  if (text.isEmpty) return [''];

  final pages = <String>[];
  int pos = 0;

  while (pos < text.length) {
    int next = pos + charsPerPage;
    if (next >= text.length) {
      pages.add(text.substring(pos).trimRight());
      break;
    }
    final bp = _safeBreak(text, next);
    pages.add(text.substring(pos, bp).trimRight());
    pos = bp;
  }

  return pages.isEmpty ? [''] : pages;
}

// ─── Widget الرئيسي ──────────────────────────────────────────────
class BookModeView extends StatefulWidget {
  final int noteId;
  final Color textColor;
  final Color noteColor;
  final String? plainContent;
  final String? deltaJson;
  final bool isMarkdown;

  const BookModeView({
    super.key,
    required this.noteId,
    required this.textColor,
    required this.noteColor,
    this.plainContent,
    this.deltaJson,
    this.isMarkdown = false,
  });

  @override
  State<BookModeView> createState() => _BookModeViewState();
}

class _BookModeViewState extends State<BookModeView> {
  late final PageController _pageController;
  double _fontSize = 18;
  bool _comfortableFont = false;
  bool _showFormatted = true; // true = منسق (Quill) | false = نص عادي
  int _currentPage = 0;
  int _savedPage = 0;

  // صفحات Delta منسقة أو نص عادي
  List<Delta>? _deltaPages;
  List<String>? _plainPages;
  int _totalPages = 1;

  static const _minFont = 14.0;
  static const _maxFont = 28.0;
  static const _prefKeyPrefix = 'reading_page_';
  static const _prefKeyFormatted = 'book_mode_show_formatted';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buildPages();
    _loadSavedPage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // خط أكبر قليلاً على الشاشات العريضة (مرة واحدة فقط)
    if (_fontSize == 18 && MediaQuery.of(context).size.width > 600) {
      _fontSize = 20;
    }
  }

  void _buildPages() {
    if (widget.isMarkdown || widget.deltaJson == null) {
      _plainPages = _splitPlainIntoPages(widget.plainContent ?? '');
      _totalPages = _plainPages!.length;
    } else {
      try {
        final rawDelta = Delta.fromJson(jsonDecode(widget.deltaJson!) as List);
        final fixedDelta = QuillMigration.fixDeltaDirections(rawDelta);
        _deltaPages = _splitDeltaIntoPages(fixedDelta);
        _totalPages = _deltaPages!.length;
      } catch (_) {
        _plainPages = _splitPlainIntoPages(widget.plainContent ?? '');
        _totalPages = _plainPages!.length;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('$_prefKeyPrefix${widget.noteId}') ?? 0;
    final savedFormatted = prefs.getBool(_prefKeyFormatted) ?? true;
    if (!mounted) return;
    final page = saved.clamp(0, _totalPages - 1);
    setState(() {
      _savedPage = page;
      _showFormatted = savedFormatted;
    });
    if (page > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(page);
      });
    }
  }

  Future<void> _savePage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefKeyPrefix${widget.noteId}', _currentPage);
    setState(() => _savedPage = _currentPage);
    if (!mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: AppLocalizations.of(context)!.readingPositionSaved,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.noteColor,
      appBar: _buildTopBar(l10n, scheme),
      body: _buildPageView(),
      bottomNavigationBar: _buildBottomBar(l10n, scheme),
    );
  }

  PreferredSizeWidget _buildTopBar(AppLocalizations l10n, ColorScheme scheme) {
    return AppBar(
      backgroundColor: widget.noteColor,
      foregroundColor: widget.textColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: widget.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${l10n.readingMode}  ${_currentPage + 1}/$_totalPages',
        style: TextStyle(
          color: widget.textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.text_decrease_rounded, color: widget.textColor),
          tooltip: 'A-',
          onPressed: _fontSize > _minFont
              ? () {
                  setState(() {
                    _fontSize -= 2;
                    _deltaPages = null;
                    _plainPages = null;
                    _buildPages();
                    _currentPage = _currentPage.clamp(0, _totalPages - 1);
                  });
                }
              : null,
        ),
        IconButton(
          icon: Icon(Icons.text_increase_rounded, color: widget.textColor),
          tooltip: 'A+',
          onPressed: _fontSize < _maxFont
              ? () {
                  setState(() {
                    _fontSize += 2;
                    _deltaPages = null;
                    _plainPages = null;
                    _buildPages();
                    _currentPage = _currentPage.clamp(0, _totalPages - 1);
                  });
                }
              : null,
        ),
        IconButton(
          icon: Icon(
            _comfortableFont
                ? Icons.font_download_rounded
                : Icons.font_download_off_rounded,
            color: _comfortableFont
                ? scheme.primary
                : widget.textColor.withValues(alpha: 0.7),
          ),
          tooltip: l10n.comfortableFont,
          onPressed: () => setState(() => _comfortableFont = !_comfortableFont),
        ),
        // زر التبديل بين التنسيق والنص العادي — يظهر فقط إذا يوجد Delta
        if (widget.deltaJson != null && !widget.isMarkdown)
          IconButton(
            icon: Icon(
              _showFormatted
                  ? Icons.format_clear_rounded
                  : Icons.format_color_text_rounded,
              color: _showFormatted
                  ? scheme.primary
                  : widget.textColor.withValues(alpha: 0.7),
            ),
            tooltip: _showFormatted ? 'نص عادي' : 'نص منسق',
            onPressed: () async {
              final next = !_showFormatted;
              setState(() => _showFormatted = next);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_prefKeyFormatted, next);
            },
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildPageView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final maxContentWidth = isWide ? 640.0 : double.infinity;
        final horizontalPadding = isWide ? 32.0 : 20.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: PageView.builder(
              controller: _pageController,
              physics: const _StiffPageScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _totalPages,
              itemBuilder: (context, index) =>
                  _buildPage(index, horizontalPadding),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(int index, double horizontalPadding) {
    if (widget.isMarkdown) {
      final pageText = _plainPages![index];
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
        child: MarkdownViewer(
          content: pageText,
          textColor: widget.textColor,
        ),
      );
    }

    // إذا المستخدم اختار النص العادي — اعرض plain بغض النظر عن وجود Delta
    if (!_showFormatted) {
      final text = _plainPages != null
          ? _plainPages![index]
          : (_deltaPages![index]
              .toList()
              .where((op) => op.isInsert && op.data is String)
              .map((op) => op.data as String)
              .join());
      return _buildPlainPage(text, horizontalPadding);
    }

    if (_deltaPages != null) {
      return _buildQuillPage(_deltaPages![index], horizontalPadding);
    }

    return _buildPlainPage(_plainPages![index], horizontalPadding);
  }

  Widget _buildQuillPage(Delta pageDelta, double horizontalPadding) {
    final fontFamily = _comfortableFont ? 'Georgia' : null;

    Document doc;
    try {
      doc = Document.fromDelta(pageDelta);
    } catch (_) {
      // إذا فشل بناء الـ Document، اعرض كنص عادي
      final text = pageDelta
          .toList()
          .where((op) => op.isInsert && op.data is String)
          .map((op) => op.data as String)
          .join();
      return _buildPlainPage(text, horizontalPadding);
    }

    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.readOnly = true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: fontFamily),
        child: QuillEditor(
          controller: controller,
          focusNode: FocusNode(),
          scrollController: ScrollController(),
          config: QuillEditorConfig(
            autoFocus: false,
            expands: true,
            scrollable: true,
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 16, horizontalPadding, 20),
            showCursor: false,
            enableInteractiveSelection: true,
            checkBoxReadOnly: true,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: _fontSize,
                  fontFamily: fontFamily,
                  height: 1.8,
                  color: widget.textColor,
                ),
                HorizontalSpacing.zero,
                VerticalSpacing.zero,
                VerticalSpacing.zero,
                null,
              ),
              lists: DefaultListBlockStyle(
                TextStyle(
                  fontSize: _fontSize,
                  fontFamily: fontFamily,
                  height: 1.8,
                  color: widget.textColor,
                ),
                HorizontalSpacing.zero,
                VerticalSpacing.zero,
                VerticalSpacing.zero,
                null,
                null,
              ),
              leading: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: _fontSize,
                  fontFamily: fontFamily,
                  height: 1.8,
                  color: widget.textColor,
                ),
                HorizontalSpacing.zero,
                VerticalSpacing.zero,
                VerticalSpacing.zero,
                null,
              ),
              h1: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: _fontSize + 8,
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                  color: widget.textColor,
                ),
                HorizontalSpacing.zero,
                const VerticalSpacing(8, 4),
                VerticalSpacing.zero,
                null,
              ),
              h2: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: _fontSize + 5,
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                  color: widget.textColor,
                ),
                HorizontalSpacing.zero,
                const VerticalSpacing(6, 3),
                VerticalSpacing.zero,
                null,
              ),
              h3: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: _fontSize + 3,
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                  color: widget.textColor,
                ),
                HorizontalSpacing.zero,
                const VerticalSpacing(4, 2),
                VerticalSpacing.zero,
                null,
              ),
              code: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: _fontSize - 2,
                  fontFamily: 'monospace',
                  height: 1.5,
                  color: widget.textColor.withValues(alpha: 0.85),
                ),
                HorizontalSpacing.zero,
                const VerticalSpacing(4, 4),
                VerticalSpacing.zero,
                BoxDecoration(
                  color: widget.textColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              quote: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: _fontSize,
                  fontFamily: fontFamily,
                  fontStyle: FontStyle.italic,
                  height: 1.8,
                  color: widget.textColor.withValues(alpha: 0.8),
                ),
                HorizontalSpacing.zero,
                const VerticalSpacing(4, 4),
                VerticalSpacing.zero,
                BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(
                      color: widget.textColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlainPage(String text, double horizontalPadding) {
    final paragraphs = text.split('\n');
    final fontFamily = _comfortableFont ? 'Georgia' : null;

    final firstNonEmpty =
        paragraphs.firstWhere((p) => p.trim().isNotEmpty, orElse: () => '');
    final pageDir = TextDirectionUtils.getDirectionForParagraph(firstNonEmpty);

    return Directionality(
      textDirection: pageDir,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
        itemCount: paragraphs.length,
        itemBuilder: (_, i) {
          final para = paragraphs[i];
          final dir = TextDirectionUtils.getDirectionForParagraph(para);
          return Directionality(
            textDirection: dir,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                para,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.8,
                  color: widget.textColor,
                  fontFamily: fontFamily,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, ColorScheme scheme) {
    final progress = _totalPages > 1 ? _currentPage / (_totalPages - 1) : 1.0;
    final savedProgress =
        _totalPages > 1 ? _savedPage / (_totalPages - 1) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: widget.noteColor,
        border: Border(
          top: BorderSide(
            color: widget.textColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // شريط التقدم مع علامة الموضع المحفوظ
              LayoutBuilder(builder: (ctx, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            widget.textColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(scheme.primary),
                      ),
                    ),
                    if (_savedPage > 0)
                      Positioned(
                        left: savedProgress * constraints.maxWidth - 1.5,
                        child: Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  // أزرار التنقل
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.chevron_left_rounded,
                        color: _currentPage > 0
                            ? widget.textColor
                            : widget.textColor.withValues(alpha: 0.3)),
                    onPressed: _currentPage > 0
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                  ),
                  Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.chevron_right_rounded,
                        color: _currentPage < _totalPages - 1
                            ? widget.textColor
                            : widget.textColor.withValues(alpha: 0.3)),
                    onPressed: _currentPage < _totalPages - 1
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                  ),
                  // الموضع المحفوظ
                  if (_savedPage > 0) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _goToPage(_savedPage),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark_rounded,
                              color: Colors.orange, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${_savedPage + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  // زر حفظ الموضع
                  TextButton.icon(
                    onPressed: _savePage,
                    icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                    label: Text(
                      l10n.saveReadingPosition,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PageScrollPhysics بعتبة أعلى للتنقل بين الصفحات ─────────────
// يتطلب سحب أقوى للانتقال للصفحة التالية/السابقة
class _StiffPageScrollPhysics extends PageScrollPhysics {
  const _StiffPageScrollPhysics()
      : super(parent: const ClampingScrollPhysics());

  @override
  _StiffPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return const _StiffPageScrollPhysics();
  }

  // رفع الحد الأدنى لسرعة السحب (الافتراضي ~365 px/s)
  @override
  double get minFlingVelocity => 800.0;

  // رفع نسبة المسافة المطلوبة للانتقال (الافتراضي 0.5 من عرض الصفحة)
  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

// (end of file)

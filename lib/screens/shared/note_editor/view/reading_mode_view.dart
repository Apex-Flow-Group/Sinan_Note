// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/core/utils/text_direction_utils.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/editor/markdown_viewer.dart';

// ─── ثوابت التقسيم ───────────────────────────────────────────────
const _charsPerPage = 1800;
const _linesPerPage = 22;

// ─── Regex للفصول: # العنوان | الفصل/Chapter | --- | فراغ مزدوج ─
final _chapterRegex = RegExp(
  r'(^#{1,6} .+$|^(الفصل|الجزء|القسم|Chapter|Part|Section)\b.+$|^-{3,}$)',
  multiLine: true,
);

// ─── تقسيم النص الذكي ────────────────────────────────────────────
List<String> splitIntoPages(String text) {
  if (text.isEmpty) return [''];

  // أولاً: قسّم عند الفصول المكتشفة
  final chapterSplits = <String>[];
  int last = 0;
  for (final match in _chapterRegex.allMatches(text)) {
    if (match.start > last) {
      chapterSplits.add(text.substring(last, match.start).trim());
    }
    last = match.start;
  }
  chapterSplits.add(text.substring(last).trim());
  chapterSplits.removeWhere((s) => s.isEmpty);

  // ثانياً: لكل قطعة، قسّمها بالأحرف والأسطر
  final pages = <String>[];
  for (final chunk in chapterSplits) {
    pages.addAll(_splitChunk(chunk));
  }
  return pages.isEmpty ? [''] : pages;
}

List<String> _splitChunk(String text) {
  final lines = text.split('\n');
  final pages = <String>[];
  final buffer = StringBuffer();
  int lineCount = 0;
  int charCount = 0;

  void flush() {
    final page = buffer.toString().trim();
    if (page.isNotEmpty) pages.add(page);
    buffer.clear();
    lineCount = 0;
    charCount = 0;
  }

  for (final line in lines) {
    final lineLen = line.length + 1;
    final wouldExceed =
        lineCount >= _linesPerPage || charCount + lineLen > _charsPerPage;

    if (wouldExceed && buffer.isNotEmpty) flush();

    buffer.writeln(line);
    lineCount++;
    charCount += lineLen;
  }
  flush();
  return pages;
}

// ─── Widget الرئيسي ──────────────────────────────────────────────
class ReadingModeView extends StatefulWidget {
  final int noteId;
  final Color textColor;
  final Color noteColor;
  final String? plainContent;
  final bool isMarkdown;

  const ReadingModeView({
    super.key,
    required this.noteId,
    required this.textColor,
    required this.noteColor,
    this.plainContent,
    this.isMarkdown = false,
  });

  @override
  State<ReadingModeView> createState() => _ReadingModeViewState();
}

class _ReadingModeViewState extends State<ReadingModeView> {
  late final PageController _pageController;
  double _fontSize = 18;
  bool _comfortableFont = false;
  int _currentPage = 0;
  int _savedPage = 0;
  late List<String> _pages;

  static const _minFont = 14.0;
  static const _maxFont = 28.0;
  static const _prefKeyPrefix = 'reading_page_';

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    _pageController = PageController();
    _loadSavedPage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _buildPages() {
    return splitIntoPages(widget.plainContent ?? '');
  }

  Future<void> _loadSavedPage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('$_prefKeyPrefix${widget.noteId}') ?? 0;
    if (!mounted) return;
    final page = saved.clamp(0, _pages.length - 1);
    setState(() => _savedPage = page);
    if (page > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(page);
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
        '${l10n.readingMode}  ${_currentPage + 1}/${_pages.length}',
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
              ? () => setState(() => _fontSize -= 2)
              : null,
        ),
        IconButton(
          icon: Icon(Icons.text_increase_rounded, color: widget.textColor),
          tooltip: 'A+',
          onPressed: _fontSize < _maxFont
              ? () => setState(() => _fontSize += 2)
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
          onPressed: () =>
              setState(() => _comfortableFont = !_comfortableFont),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemCount: _pages.length,
      itemBuilder: (context, index) => _buildPage(index),
    );
  }

  Widget _buildPage(int index) {
    final pageText = _pages[index];

    if (widget.isMarkdown) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: MarkdownViewer(
          content: pageText,
          textColor: widget.textColor,
        ),
      );
    }

    return _PlainPage(
      text: pageText,
      textColor: widget.textColor,
      fontSize: _fontSize,
      comfortableFont: _comfortableFont,
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, ColorScheme scheme) {
    final progress = _pages.length > 1 ? _currentPage / (_pages.length - 1) : 1.0;
    final savedProgress = _pages.length > 1 ? _savedPage / (_pages.length - 1) : 0.0;

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
                        valueColor:
                            AlwaysStoppedAnimation(scheme.primary),
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
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.chevron_left_rounded,
                        color: _currentPage > 0
                            ? widget.textColor
                            : widget.textColor.withValues(alpha: 0.3)),
                    onPressed:
                        _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                  ),
                  Text(
                    '${_currentPage + 1} / ${_pages.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.chevron_right_rounded,
                        color: _currentPage < _pages.length - 1
                            ? widget.textColor
                            : widget.textColor.withValues(alpha: 0.3)),
                    onPressed: _currentPage < _pages.length - 1
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

// ─── صفحة النص العادي مع اتجاه كل فقرة ──────────────────────────
class _PlainPage extends StatelessWidget {
  final String text;
  final Color textColor;
  final double fontSize;
  final bool comfortableFont;

  const _PlainPage({
    required this.text,
    required this.textColor,
    required this.fontSize,
    required this.comfortableFont,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphs = text.split('\n');
    final fontFamily = comfortableFont ? 'Georgia' : null;

    // اتجاه الصفحة من أول فقرة غير فارغة
    final firstNonEmpty = paragraphs.firstWhere((p) => p.trim().isNotEmpty, orElse: () => '');
    final pageDir = TextDirectionUtils.getDirectionForParagraph(firstNonEmpty);

    return Directionality(
      textDirection: pageDir,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                  fontSize: fontSize,
                  height: 1.8,
                  color: textColor,
                  fontFamily: fontFamily,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



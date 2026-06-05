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

// ─── ثوابت التقسيم ───────────────────────────────────────────────
const _linesPerPage = 18;

// ─── تقسيم Delta لصفحات مع الحفاظ على التنسيق ─────────────────────
List<Delta> _splitDeltaIntoPages(Delta delta) {
  final pages = <Delta>[];
  var currentPage = Delta();
  int lineCount = 0;

  for (final op in delta.toList()) {
    if (!op.isInsert) continue;
    final data = op.data;

    if (data is! String) {
      // embed (صورة، إلخ) — أضفها للصفحة الحالية
      currentPage.insert(data, op.attributes);
      continue;
    }

    // قسّم النص عند الأسطر الجديدة
    final parts = data.split('\n');
    for (int i = 0; i < parts.length; i++) {
      final isLastPart = i == parts.length - 1;
      final text = parts[i];

      if (text.isNotEmpty) {
        currentPage.insert(text, op.attributes);
      }

      if (!isLastPart) {
        // هذا سطر جديد — يحمل attributes الـ block (direction, align, list, header...)
        currentPage.insert('\n', op.attributes);
        lineCount++;

        if (lineCount >= _linesPerPage) {
          // أنهِ الصفحة الحالية
          pages.add(currentPage);
          currentPage = Delta();
          lineCount = 0;
        }
      }
    }
  }

  // أضف ما تبقى كصفحة أخيرة
  if (currentPage.isNotEmpty) {
    // تأكد أن الـ Delta ينتهي بـ \n (مطلوب لـ Document)
    final lastOp = currentPage.toList().last;
    if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
      currentPage.insert('\n');
    }
    pages.add(currentPage);
  }

  return pages.isEmpty ? [Delta()..insert('\n')] : pages;
}

List<String> _splitPlainIntoPages(String text) {
  if (text.isEmpty) return [''];
  final lines = text.split('\n');
  final pages = <String>[];
  final buffer = StringBuffer();
  int lineCount = 0;

  for (final line in lines) {
    if (lineCount >= _linesPerPage && buffer.isNotEmpty) {
      pages.add(buffer.toString().trimRight());
      buffer.clear();
      lineCount = 0;
    }
    buffer.writeln(line);
    lineCount++;
  }
  final remaining = buffer.toString().trimRight();
  if (remaining.isNotEmpty) pages.add(remaining);
  return pages.isEmpty ? [''] : pages;
}

// ─── Widget الرئيسي ──────────────────────────────────────────────
class ReadingModeView extends StatefulWidget {
  final int noteId;
  final Color textColor;
  final Color noteColor;
  final String? plainContent;
  final String? deltaJson;
  final bool isMarkdown;

  const ReadingModeView({
    super.key,
    required this.noteId,
    required this.textColor,
    required this.noteColor,
    this.plainContent,
    this.deltaJson,
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

  // صفحات Delta منسقة أو نص عادي
  List<Delta>? _deltaPages;
  List<String>? _plainPages;
  int _totalPages = 1;

  static const _minFont = 14.0;
  static const _maxFont = 28.0;
  static const _prefKeyPrefix = 'reading_page_';

  @override
  void initState() {
    super.initState();
    _buildPages();
    _pageController = PageController();
    _loadSavedPage();
  }

  void _buildPages() {
    if (widget.isMarkdown || widget.deltaJson == null) {
      _plainPages = _splitPlainIntoPages(widget.plainContent ?? '');
      _totalPages = _plainPages!.length;
    } else {
      try {
        final rawDelta = Delta.fromJson(jsonDecode(widget.deltaJson!) as List);
        // صحّح اتجاهات الـ blocks قبل التقسيم
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
    if (!mounted) return;
    final page = saved.clamp(0, _totalPages - 1);
    setState(() => _savedPage = page);
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
          onPressed: () => setState(() => _comfortableFont = !_comfortableFont),
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
      itemCount: _totalPages,
      itemBuilder: (context, index) => _buildPage(index),
    );
  }

  Widget _buildPage(int index) {
    if (widget.isMarkdown) {
      final pageText = _plainPages![index];
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: MarkdownViewer(
          content: pageText,
          textColor: widget.textColor,
        ),
      );
    }

    if (_deltaPages != null) {
      return _buildQuillPage(_deltaPages![index]);
    }

    return _buildPlainPage(_plainPages![index]);
  }

  Widget _buildQuillPage(Delta pageDelta) {
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
      return _buildPlainPage(text);
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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

  Widget _buildPlainPage(String text) {
    final paragraphs = text.split('\n');
    final fontFamily = _comfortableFont ? 'Georgia' : null;

    final firstNonEmpty =
        paragraphs.firstWhere((p) => p.trim().isNotEmpty, orElse: () => '');
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

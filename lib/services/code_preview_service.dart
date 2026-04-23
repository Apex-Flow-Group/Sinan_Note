// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// عرض معاينة منسقة للكود — لا يُشغّل الكود ولا يغيره
class CodePreviewService {
  static bool supportsPreview(String? language) => language != null;

  static Future<void> preview(
    BuildContext context,
    String language,
    String code,
  ) async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PreviewSheet(language: language, code: code),
      );
    } catch (_) {}
  }
}

// ── Bottom sheet ───────────────────────────────────────────────────────────

class _PreviewSheet extends StatefulWidget {
  final String language;
  final String code;

  const _PreviewSheet({required this.language, required this.code});

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _searchVisible = false;

  late final String _displayCode;

  @override
  void initState() {
    super.initState();
    _displayCode = _prepareCode(widget.language, widget.code);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _prepareCode(String language, String code) {
    if (language.toUpperCase() == 'JSON') {
      try {
        final decoded = jsonDecode(code);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return code;
      }
    }
    return code;
  }

  void _copyAll() {
    try {
      Clipboard.setData(ClipboardData(text: _displayCode));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم النسخ'
                  : 'Copied',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(Icons.preview_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.language} Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // زر البحث
                  IconButton(
                    icon: Icon(
                      _searchVisible
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      size: 20,
                    ),
                    tooltip: isAr ? 'بحث' : 'Search',
                    onPressed: () => setState(() {
                      _searchVisible = !_searchVisible;
                      if (!_searchVisible) {
                        _query = '';
                        _searchController.clear();
                      }
                    }),
                  ),
                  // زر النسخ
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: isAr ? 'نسخ' : 'Copy',
                    onPressed: _copyAll,
                  ),
                  // زر الإغلاق
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // شريط البحث
            if (_searchVisible)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isAr ? 'ابحث في الكود...' : 'Search in code...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => setState(() {
                              _query = '';
                              _searchController.clear();
                            }),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            // عداد النتائج
            if (_searchVisible && _query.isNotEmpty)
              _SearchResultCount(
                  code: _displayCode, query: _query, scheme: scheme),
            const Divider(height: 1),
            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: _CodeWithLineNumbers(
                  code: _displayCode,
                  isDark: isDark,
                  query: _query,
                  scheme: scheme,
                  // JSON parse error
                  parseError: widget.language.toUpperCase() == 'JSON' &&
                          _displayCode == widget.code &&
                          widget.code.trim().isNotEmpty
                      ? _getJsonError(widget.code)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getJsonError(String code) {
    try {
      jsonDecode(code);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// ── عداد نتائج البحث ───────────────────────────────────────────────────────

class _SearchResultCount extends StatelessWidget {
  final String code;
  final String query;
  final ColorScheme scheme;

  const _SearchResultCount({
    required this.code,
    required this.query,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final count =
          RegExp(RegExp.escape(query), caseSensitive: false).allMatches(code).length;
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            isAr ? '$count نتيجة' : '$count result${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11,
              color: count > 0
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

// ── الكود مع أرقام الأسطر والبحث ──────────────────────────────────────────

class _CodeWithLineNumbers extends StatelessWidget {
  final String code;
  final bool isDark;
  final String query;
  final ColorScheme scheme;
  final String? parseError;

  const _CodeWithLineNumbers({
    required this.code,
    required this.isDark,
    required this.query,
    required this.scheme,
    this.parseError,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final bgColor =
          isDark ? const Color(0xFF12121F) : const Color(0xFFF6F8FA);
      final borderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08);
      final textColor = isDark ? Colors.white70 : Colors.black87;
      final highlightColor =
          scheme.primary.withValues(alpha: isDark ? 0.35 : 0.25);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رسالة خطأ JSON إن وجدت
          if (parseError != null) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                'JSON: $parseError',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          // الكود
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: query.isEmpty
                  ? SelectableText(
                      code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.6,
                        color: textColor,
                      ),
                    )
                  : _buildHighlightedText(
                      code, query, textColor, highlightColor),
            ),
          ),
        ],
      );
    } catch (_) {
      // fallback بسيط
      return SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
    }
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    Color textColor,
    Color highlightColor,
  ) {
    try {
      final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
      final matches = pattern.allMatches(text).toList();
      if (matches.isEmpty) {
        return SelectableText(
          text,
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 13, height: 1.6, color: textColor),
        );
      }

      final spans = <TextSpan>[];
      int last = 0;
      for (final m in matches) {
        if (m.start > last) {
          spans.add(TextSpan(
            text: text.substring(last, m.start),
            style: TextStyle(color: textColor),
          ));
        }
        spans.add(TextSpan(
          text: text.substring(m.start, m.end),
          style: TextStyle(
            color: textColor,
            backgroundColor: highlightColor,
            fontWeight: FontWeight.bold,
          ),
        ));
        last = m.end;
      }
      if (last < text.length) {
        spans.add(TextSpan(
          text: text.substring(last),
          style: TextStyle(color: textColor),
        ));
      }

      return SelectableText.rich(
        TextSpan(
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 13, height: 1.6),
          children: spans,
        ),
      );
    } catch (_) {
      return SelectableText(
        text,
        style: TextStyle(
            fontFamily: 'monospace', fontSize: 13, height: 1.6, color: textColor),
      );
    }
  }
}

// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// MarkdownViewer — عارض Markdown كامل قابل للتوسعة
// كل فقرة تحدد اتجاهها من أول حرف مؤثر فيها (نفس منطق المحرر)
// كتل الكود: syntax highlighting + زر نسخ

import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

// ── Code Block Builder ────────────────────────────────────────────────────────

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final Color textColor;
  final bool isDark;

  _CodeBlockBuilder({required this.textColor, required this.isDark});

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // استخراج اللغة من class="language-xxx"
    final language =
        (element.attributes['class'] ?? '').replaceFirst('language-', '');
    final code = element.textContent;
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;

    return _CodeBlock(
      code: code,
      language: language.isEmpty ? 'plaintext' : language,
      theme: theme,
      isDark: isDark,
      textColor: textColor,
    );
  }
}

class _CodeBlock extends StatefulWidget {
  final String code;
  final String language;
  final Map<String, TextStyle> theme;
  final bool isDark;
  final Color textColor;

  const _CodeBlock({
    required this.code,
    required this.language,
    required this.theme,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg =
        widget.isDark ? const Color(0xFF282C34) : const Color(0xFFFAFAFA);
    final borderColor = widget.textColor.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── شريط العنوان ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.textColor.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              border:
                  Border(bottom: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: Row(
              children: [
                // اسم اللغة
                Flexible(
                  child: Text(
                    widget.language,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: widget.textColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // زر النسخ
                GestureDetector(
                  onTap: _copy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? const Icon(Icons.check_rounded,
                            key: ValueKey('check'),
                            size: 16,
                            color: Colors.green)
                        : Icon(Icons.copy_rounded,
                            key: const ValueKey('copy'),
                            size: 16,
                            color: widget.textColor.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          // ── الكود مع highlighting ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: HighlightView(
                widget.code,
                language: widget.language,
                theme: widget.theme,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MarkdownViewer ────────────────────────────────────────────────────────────

class MarkdownViewer extends StatelessWidget {
  final String content;
  final Color textColor;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const MarkdownViewer({
    super.key,
    required this.content,
    required this.textColor,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
  });

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final blockquoteBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final dividerColor = textColor.withValues(alpha: 0.2);
    final linkColor = isDark ? Colors.lightBlueAccent : Colors.blue;
    final base = TextStyle(color: textColor, fontSize: 16, height: 1.6);

    return MarkdownStyleSheet(
      p: base,
      pPadding: EdgeInsets.zero,
      h1: base.copyWith(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3),
      h2: base.copyWith(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
      h3: base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
      h4: base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
      h5: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
      h6: base.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: textColor.withValues(alpha: 0.7)),
      h1Padding: const EdgeInsets.only(top: 12, bottom: 4),
      h2Padding: const EdgeInsets.only(top: 10, bottom: 4),
      h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h4Padding: const EdgeInsets.only(top: 6, bottom: 2),
      h5Padding: const EdgeInsets.only(top: 4, bottom: 2),
      h6Padding: const EdgeInsets.only(top: 4, bottom: 2),
      strong: base.copyWith(fontWeight: FontWeight.bold),
      em: base.copyWith(fontStyle: FontStyle.italic),
      del: base.copyWith(
          decoration: TextDecoration.lineThrough,
          color: textColor.withValues(alpha: 0.6)),
      a: base.copyWith(color: linkColor, decoration: TextDecoration.underline),
      code: base.copyWith(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: codeBg,
        color: isDark ? Colors.greenAccent : Colors.green.shade800,
      ),
      // كتل الكود تُعالج بـ _CodeBlockBuilder — هذا للـ fallback فقط
      codeblockDecoration: const BoxDecoration(),
      codeblockPadding: EdgeInsets.zero,
      blockquote: base.copyWith(
          fontStyle: FontStyle.italic,
          color: textColor.withValues(alpha: 0.75)),
      blockquoteDecoration: BoxDecoration(
        color: blockquoteBg,
        border: Border(
            left:
                BorderSide(color: textColor.withValues(alpha: 0.4), width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      blockquotePadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      listBullet: base.copyWith(fontSize: 16),
      listBulletPadding: const EdgeInsets.only(right: 8),
      listIndent: 20,
      tableHead: base.copyWith(fontWeight: FontWeight.bold),
      tableBody: base,
      tableBorder: TableBorder.all(color: dividerColor, width: 0.8),
      tableHeadAlign: TextAlign.center,
      tableCellsPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      tableColumnWidth: const FlexColumnWidth(),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor, width: 1.5)),
      ),
      checkbox: base.copyWith(color: linkColor),
      blockSpacing: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dir = TextDirectionUtils.getDirection(content);
    final sanitized = content.replaceAllMapped(
      RegExp(r'<kbd>(.*?)</kbd>', caseSensitive: false),
      (m) => '`${m[1]}`',
    );

    return ScrollbarTheme(
      data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
      child: Directionality(
        textDirection: dir,
        child: MarkdownBody(
          data: sanitized,
          selectable: true,
          styleSheet: _buildStyleSheet(context),
          extensionSet: md.ExtensionSet(
            [...md.ExtensionSet.gitHubFlavored.blockSyntaxes],
            [
              md.EmojiSyntax(),
              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            ],
          ),
          onTapLink: _onTapLink,
          builders: {
            'code': _CodeBlockBuilder(textColor: textColor, isDark: isDark),
          },
          imageBuilder: (uri, title, alt) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                uri.toString(),
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: textColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: textColor.withValues(alpha: 0.4), size: 18),
                      const SizedBox(width: 6),
                      Text(alt ?? 'Image',
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

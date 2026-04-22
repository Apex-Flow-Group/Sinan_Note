// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CodeEditorToolbar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Function(String) onInsertSymbol;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onRunCode;
  final VoidCallback? onExportCode;
  final VoidCallback? onBackgroundColorTap;
  final String? detectedLanguage;
  final Function(String)? onLanguageChanged;

  const CodeEditorToolbar({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.onInsertSymbol,
    required this.onUndo,
    required this.onRedo,
    this.onRunCode,
    this.onExportCode,
    this.onBackgroundColorTap,
    this.detectedLanguage,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're on desktop
    final isDesktop = Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Language indicator - Always visible
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: onLanguageChanged != null
                        ? () => _showLanguageSelector(context)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: textColor.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.code,
                              color: textColor.withValues(alpha: 0.7),
                              size: 16),
                          const SizedBox(width: 6),
                          Text(
                            detectedLanguage != null && detectedLanguage!.startsWith('custom:')
                                ? '.${detectedLanguage!.substring(7)}'
                                : (detectedLanguage ?? 'Auto'),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (onLanguageChanged != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down,
                                color: textColor.withValues(alpha: 0.5),
                                size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onBackgroundColorTap != null)
                    _buildIconBtn(
                        Icons.color_lens, onBackgroundColorTap, Colors.purple),
                  if (onRunCode != null)
                    _buildIconBtn(Icons.play_arrow, onRunCode, Colors.green),
                  if (onExportCode != null)
                    _buildIconBtn(Icons.file_download_outlined, onExportCode,
                        Colors.blue),
                ],
              ),
            ),
            // Symbol row with scroll support
            isDesktop ? _buildDesktopSymbolRow() : _buildMobileSymbolRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSymbolRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _buildSymbolButtons(),
      ),
    );
  }

  Widget _buildDesktopSymbolRow() {
    final scrollController = ScrollController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            // Left scroll button
            IconButton(
              icon: Icon(Icons.chevron_left, color: textColor),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                scrollController.animateTo(
                  scrollController.offset - 200,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
            // Scrollable content with mouse drag support
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildSymbolButtons(),
                  ),
                ),
              ),
            ),
            // Right scroll button
            IconButton(
              icon: Icon(Icons.chevron_right, color: textColor),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                scrollController.animateTo(
                  scrollController.offset + 200,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSymbolButtons() {
    return [
      _buildIconBtn(Icons.undo, onUndo, textColor),
      _buildIconBtn(Icons.redo, onRedo, textColor),
      const SizedBox(width: 8),
      _buildSymbolBtn('{ }', () => onInsertSymbol('{}')),
      _buildSymbolBtn('[ ]', () => onInsertSymbol('[]')),
      _buildSymbolBtn('( )', () => onInsertSymbol('()')),
      _buildSymbolBtn('< >', () => onInsertSymbol('<>')),
      _buildSymbolBtn('" "', () => onInsertSymbol('""')),
      _buildSymbolBtn("' '", () => onInsertSymbol("''")),
      _buildSymbolBtn(';', () => onInsertSymbol(';')),
      _buildSymbolBtn(':', () => onInsertSymbol(':')),
      _buildSymbolBtn('=', () => onInsertSymbol('=')),
      _buildSymbolBtn('->', () => onInsertSymbol('->')),
      _buildSymbolBtn('=>', () => onInsertSymbol('=>')),
      _buildSymbolBtn('//', () => onInsertSymbol('//')),
      _buildSymbolBtn('/*', () => onInsertSymbol('/**/')),
    ];
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final languages = [
      'Auto',
      'Python',
      'JavaScript',
      'TypeScript',
      'Java',
      'Dart',
      'HTML',
      'CSS',
      'SVG',
      'SQL',
      'C++',
      'C',
      'C#',
      'Swift',
      'Kotlin',
      'Go',
      'Rust',
      'PHP',
      'Ruby',
      'Bash',
      'JSON',
      'YAML',
      'TOML',
      'Markdown',
      'XML',
      'Lua',
      'R',
      'Dockerfile',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - ثابت
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.language, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.selectLanguage,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content - قابل للسكرول
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length + 1,
                itemBuilder: (context, index) {
                  if (index == languages.length) {
                    return ListTile(
                      leading: Icon(Icons.edit_outlined,
                          color: colorScheme.secondary),
                      title: Text(l10n.otherExtension),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showCustomExtensionDialog(context);
                      },
                    );
                  }

                  final lang = languages[index];
                  final isSelected =
                      (lang == 'Auto' && detectedLanguage == null) ||
                          (lang == detectedLanguage);
                  return ListTile(
                    leading: Icon(
                      lang == 'Auto' ? Icons.auto_awesome : Icons.code,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    title: Text(
                      lang,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (onLanguageChanged != null) {
                        onLanguageChanged!(lang);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomExtensionDialog(BuildContext context) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.otherExtension),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'e.g. vue, proto, graphql',
            prefixText: '.',
            prefixStyle: const TextStyle(
                fontFamily: 'monospace', fontSize: 16),
            enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: colorScheme.outline)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorScheme.primary)),
          ),
          onSubmitted: (val) {
            _applyCustomExtension(ctx, val);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => _applyCustomExtension(ctx, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _applyCustomExtension(BuildContext ctx, String raw) {
    final ext = raw.trim().replaceAll('.', '').toLowerCase();
    if (ext.isNotEmpty && onLanguageChanged != null) {
      Navigator.pop(ctx);
      // Pass as custom format: "custom:ext"
      onLanguageChanged!('custom:$ext');
    }
  }

  Widget _buildSymbolBtn(String symbol, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: textColor.withValues(alpha: 0.2),
          highlightColor: textColor.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback? onTap, Color color) {
    final isEnabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? color.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? color.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isEnabled ? color : Colors.grey,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

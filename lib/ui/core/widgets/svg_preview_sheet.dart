// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

/// SVG Service - Preview and export SVG files
class SvgService {
  /// يعرض الـ SVG داخل التطبيق في bottom sheet
  static Future<void> previewSvgCode(
      BuildContext context, String svgCode) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: _SvgPreviewSheet(svgCode: svgCode),
      ),
    );
  }

  /// Exports SVG code as a .svg file and shares it via the system share sheet.
  static Future<void> exportSvgFile(String svgCode, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = fileName.endsWith('.svg') ? fileName : '$fileName.svg';
    final file = File('${tempDir.path}/$safeName');
    await file.writeAsString(svgCode);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/svg+xml')],
      subject: safeName,
    );
  }
}

class _SvgPreviewSheet extends StatelessWidget {
  final String svgCode;

  const _SvgPreviewSheet({required this.svgCode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.svgPreviewTitle,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // SVG content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: _buildSvgWidget(context, scheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSvgWidget(BuildContext context, ColorScheme scheme) {
    try {
      return SvgPicture.string(
        svgCode,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const CircularProgressIndicator(),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: context.colors.danger.withValues(alpha: 0.3)),
        ),
        child: Text(
          AppLocalizations.of(context)!.invalidSvg('$e'),
          style: context.text.bodySmall?.copyWith(color: context.colors.danger),
        ),
      );
    }
  }
}

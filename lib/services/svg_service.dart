// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// SVG Service - Preview and export SVG files
/// Uses external browser for preview to support SMIL/CSS animations.
class SvgService {
  /// Wraps SVG code in a responsive HTML page and opens it in the system browser.
  static Future<void> previewSvgCode(String svgCode) async {
    final html = '''<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background-color: #1a1a2e;
      }
      svg { max-width: 100%; max-height: 100vh; }
    </style>
  </head>
  <body>$svgCode</body>
</html>''';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/sinan_preview.html');
    await file.writeAsString(html);

    final uri = Uri.file(file.path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open browser for SVG preview');
    }
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

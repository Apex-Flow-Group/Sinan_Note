// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

/// Terms of Service Screen
/// 
/// Displays the Terms of Service from local markdown files.
/// Files are stored in assets/legal/ for offline access.
/// 
/// Features:
/// - Bilingual support (Arabic/English)
/// - Markdown rendering with flutter_markdown
/// - Selectable text for copying
/// - Works offline (local assets)
/// 
/// Note: For About screen, terms are loaded from online URLs
/// for easy updates. This screen is for Tour/Setup only.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsOfService),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(
          isArabic 
            ? 'assets/legal/TERMS_OF_SERVICE_AR.md'
            : 'assets/legal/TERMS_OF_SERVICE_EN.md',
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data!,
              selectable: true,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

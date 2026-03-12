// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;
    final url = isArabic
        ? 'https://apexflow.now/ar/projects/sinan-note/terms'
        : 'https://apexflow.now/en/projects/sinan-note/terms';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsOfService)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_browser, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.launch),
                label: Text(l10n.termsOfService),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

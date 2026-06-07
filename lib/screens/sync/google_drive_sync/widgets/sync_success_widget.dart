// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

class SyncSuccessWidget extends StatefulWidget {
  const SyncSuccessWidget({super.key});

  @override
  State<SyncSuccessWidget> createState() => _SyncSuccessWidgetState();
}

class _SyncSuccessWidgetState extends State<SyncSuccessWidget> {
  @override
  void initState() {
    super.initState();
    // الخروج تلقائياً بعد ثانيتين
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true); // true = success
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أيقونة النجاح
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 24),

          // رسالة النجاح
          Text(
            l10n.syncSuccess,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


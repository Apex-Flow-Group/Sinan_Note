// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

/// Widget يعرض شاشة فارغة عندما لا توجد ملاحظة مختارة
/// 
/// يستخدم في Details Panel عندما:
/// - لم يختر المستخدم أي ملاحظة بعد
/// - تم مسح الملاحظة المختارة
/// - تم حذف أو نقل الملاحظة المختارة
class EmptyDetailsView extends StatelessWidget {
  const EmptyDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_rounded, size: 32, color: color),
          const SizedBox(height: 12),
          Icon(Icons.note_outlined, size: 64, color: color),
          const SizedBox(height: 12),
          Text(
            l10n.selectNote,
            style: TextStyle(fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}


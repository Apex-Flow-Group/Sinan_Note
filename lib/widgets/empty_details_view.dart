// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

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
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أيقونة ملاحظة
          Icon(
            Icons.note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          
          const SizedBox(height: 16),
          
          // رسالة إرشادية
          Text(
            l10n.selectNote,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

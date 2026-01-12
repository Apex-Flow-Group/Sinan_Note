// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../screens/main_layout_screen.dart';
import '../../../services/settings_provider.dart';

class TransferPromptDialog {
  static void show(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A2332), Color(0xFF0A1929)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync_alt, size: 64, color: Color(0xFFFFD700)),
            const SizedBox(height: 24),
            Text(
              isArabic ? 'هل لديك ملاحظات محفوظة؟' : 'Have saved notes?',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic
                  ? 'انقلها من هاتفك القديم الآن'
                  : 'Transfer from your old phone now',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // إغلاق الـ Dialog
                await Navigator.pushNamed(
                    context, '/transfer'); // فتح Sinan Transfer وانتظار العودة
                await Provider.of<SettingsProvider>(context, listen: false)
                    .completeSetup();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const MainLayoutScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0A1929),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: Text(
                isArabic ? 'نعم، استعد الآن' : 'Yes, Restore Now',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await Provider.of<SettingsProvider>(context, listen: false)
                    .completeSetup();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const MainLayoutScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text(
                isArabic ? 'لا، ابدأ من جديد' : 'No, Start Fresh',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

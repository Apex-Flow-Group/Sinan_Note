// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class TransferAgreementDialog {
  static Future<bool?> show(
      BuildContext context, bool isArabic, int lockedCount) {
    bool agreed = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'تحذير أمني' : 'Security Warning',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      isArabic
                          ? '''تحذير هام - نقل البيانات

تحذير: لديك $lockedCount ملاحظة مقفلة ومشفرة.

سياسة النقل:
لأسباب أمنية، لن يتم نقل الملاحظات المقفلة عبر Sinan Transfer.

ما سيحدث:
• سيتم نقل جميع الملاحظات العادية (غير المقفلة).
• سيتم استبعاد الملاحظات المقفلة تلقائياً.
• ستبقى الملاحظات المقفلة على الجهاز القديم.

لماذا لا يتم نقلها؟
1. الأمان:
   • الملاحظات المقفلة مشفرة بمفتاح خاص بجهازك.
   • لا يمكن فك تشفيرها على جهاز آخر.
   • نقلها سيؤدي لفقدان البيانات نهائياً.

2. الحماية:
   • منع نقل الملاحظات الحساسة عبر الشبكة.
   • حماية خصوصيتك في حالة اعتراض النقل.

كيف تنقل الملاحظات المقفلة؟
إذا كنت تريد نقلها:
1. افتح تبويب الخزنة.
2. اسحب لليمين على الملاحظة → "فك القفل".
3. ستصبح ملاحظة عادية ويمكن نقلها.
4. بعد النقل، يمكنك قفلها مجدداً على الجهاز الجديد.

إخلاء المسؤولية:
• Apex Flow Group غير مسؤولة عن فقدان الملاحظات المقفلة.
• هذه سياسة أمنية لحماية بياناتك.
• أنت المسؤول عن فك قفل الملاحظات قبل النقل.

بالمتابعة، أنت تقر بأنك:
✓ فهمت أن الملاحظات المقفلة لن يتم نقلها.
✓ تتحمل مسؤولية فك قفلها إذا أردت نقلها.
✓ تدرك أن هذه سياسة أمنية لحمايتك.'''
                          : '''Important Warning - Data Transfer

Warning: You have $lockedCount locked and encrypted notes.

Transfer Policy:
For security reasons, locked notes will NOT be transferred via Sinan Transfer.

What will happen:
• All regular (unlocked) notes will be transferred.
• Locked notes will be automatically excluded.
• Locked notes will remain on the old device.

Why not transfer them?
1. Security:
   • Locked notes are encrypted with your device-specific key.
   • They cannot be decrypted on another device.
   • Transferring them would result in permanent data loss.

2. Protection:
   • Prevents transfer of sensitive notes over network.
   • Protects your privacy if transfer is intercepted.

How to transfer locked notes?
If you want to transfer them:
1. Open the Vault tab.
2. Swipe right on the note → "Unlock".
3. It becomes a regular note and can be transferred.
4. After transfer, you can lock it again on the new device.

Disclaimer:
• Apex Flow Group is NOT responsible for loss of locked notes.
• This is a security policy to protect your data.
• You are responsible for unlocking notes before transfer.

By continuing, you acknowledge that:
✓ You understand that locked notes will NOT be transferred.
✓ You take responsibility for unlocking them if you want to transfer.
✓ You understand this is a security policy for your protection.''',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: agreed,
                  onChanged: (val) =>
                      setDialogState(() => agreed = val ?? false),
                  title: Text(
                    isArabic
                        ? 'نعم، فهمت وأوافق على المتابعة'
                        : 'Yes, I understand and agree to continue',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: agreed ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: agreed ? Colors.orange : Colors.grey,
              ),
              child: Text(isArabic ? 'متابعة' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

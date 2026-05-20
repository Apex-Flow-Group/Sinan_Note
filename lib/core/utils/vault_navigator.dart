// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/screens/auth/locked_notes_intro_screen.dart';
import 'package:sinan_note/screens/auth/pin_lock_screen.dart';
import 'package:sinan_note/screens/auth/vault_reset_screen.dart';
import 'package:sinan_note/screens/auth/vault_unlock_screen.dart';
import 'package:sinan_note/screens/desktop/locked_notes_screen_responsive.dart';

/// مركز تنقل الخزنة — مصدر واحد لكل انتقالات الخزنة.
///
/// بدلاً من أن تعرف كل شاشة عنوان الشاشة التالية مباشرة،
/// تستدعي [VaultNavigator] الذي يملك الخريطة كاملة.
///
/// الاستخدام:
/// ```dart
/// VaultNavigator.toLockedNotes(context);
/// VaultNavigator.toUnlock(context);
/// VaultNavigator.toIntro(context);
/// VaultNavigator.toReset(context);
/// VaultNavigator.exitVault(context);
/// ```
abstract class VaultNavigator {
  /// اسم route الشاشة الرئيسية — يُستخدم في [exitVault]
  static const String mainLayoutRouteName = '/main';

  /// الانتقال لشاشة الملاحظات المقفلة (يستبدل الشاشة الحالية)
  /// الانتقال لشاشة الملاحظات المقفلة (يستبدل الشاشة الحالية)
  static void toLockedNotes(BuildContext context) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LockedNotesScreenResponsive(),
        settings: const RouteSettings(name: '/vault/locked'),
      ),
    );
  }

  /// فتح الخزنة فوق الشاشة الحالية (push بدلاً من pushReplacement).
  /// يُستخدم من الـ Drawer حيث نحتاج الحفاظ على `/main` في الـ stack
  /// حتى يعمل [exitVault] بشكل صحيح.
  static void pushLockedNotes(NavigatorState navigator) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const LockedNotesScreenResponsive(),
        settings: const RouteSettings(name: '/vault/locked'),
      ),
    );
  }

  /// الانتقال لشاشة فتح الخزنة (يستبدل الشاشة الحالية)
  static void toUnlock(BuildContext context, {bool biometricFailed = false}) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VaultUnlockScreen(biometricFailed: biometricFailed),
        settings: const RouteSettings(name: '/vault/unlock'),
      ),
    );
  }

  /// الانتقال لشاشة إعداد الخزنة لأول مرة (يستبدل الشاشة الحالية)
  /// يُستخدم من VaultEntryScreen حيث /main موجود في الـ stack
  static void toIntro(BuildContext context) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LockedNotesIntroScreen(),
        settings: const RouteSettings(name: '/vault/intro'),
      ),
    );
  }

  /// فتح شاشة الجولة فوق الشاشة الحالية (push بدلاً من pushReplacement).
  /// يُستخدم من الـ Drawer مباشرة حيث /main هو الشاشة الحالية.
  static void pushIntro(NavigatorState navigator) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const LockedNotesIntroScreen(),
        settings: const RouteSettings(name: '/vault/intro'),
      ),
    );
  }

  /// الانتقال لشاشة PIN (يستبدل الشاشة الحالية)
  /// [isSetup]: true عند إعداد PIN لأول مرة
  static void toPinLock(
    BuildContext context, {
    required bool isSetup,
    required VoidCallback onSuccess,
  }) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PinLockScreen(
          isSetup: isSetup,
          autoBiometric: true,
          onSuccess: onSuccess,
        ),
        settings: const RouteSettings(name: '/vault/pin'),
      ),
    );
  }

  /// الانتقال لشاشة إعادة تعيين تشفير الخزنة (push فوق الشاشة الحالية)
  static void toReset(BuildContext context) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VaultResetScreen(),
        settings: const RouteSettings(name: '/vault/reset'),
      ),
    );
  }

  /// الخروج من الخزنة والعودة للشاشة الرئيسية.
  ///
  /// يستخدم [mainLayoutRouteName] للتحقق من الـ route بدلاً من
  /// الاعتماد على `route.isFirst` الهش.
  /// rootNavigator: true لأن الخزنة تُفتح فوق الـ root Navigator.
  static void exitVault(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil(
      (route) => route.settings.name == mainLayoutRouteName || route.isFirst,
    );
  }
}

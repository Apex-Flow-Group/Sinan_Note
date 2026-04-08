// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/auth/locked_notes_intro_screen.dart';
import 'package:apex_note/screens/auth/vault_unlock_screen.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:flutter/material.dart';

/// نقطة الدخول الرئيسية للخزنة
/// تتحقق من الحالة وتوجه للشاشة المناسبة
class VaultEntryScreen extends StatefulWidget {
  const VaultEntryScreen({super.key});

  @override
  State<VaultEntryScreen> createState() => _VaultEntryScreenState();
}

class _VaultEntryScreenState extends State<VaultEntryScreen> {
  @override
  void initState() {
    super.initState();
    _checkVaultStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _checkVaultStatus() async {
    // التحقق من وجود ملاحظات مقفلة
    final dbService = IsarDatabaseService();
    final lockedNotes = await dbService.getLockedNotes();

    // التحقق من وجود خزنة جديدة
    final hasNewVault = await VaultService.isVaultSetup();

    // إذا كانت هناك ملاحظات مقفلة ولا توجد خزنة → إنشاء خزنة جديدة
    if (lockedNotes.isNotEmpty && !hasNewVault) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LockedNotesIntroScreen(),
          ),
        );
      }
      return;
    }

    if (!hasNewVault) {
      // الحالة 1: لا توجد خزنة → Wizard إنشاء جديدة
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LockedNotesIntroScreen(),
          ),
        );
      }
      return;
    }

    // توجد خزنة، التحقق من البصمة
    final biometricEnabled = await VaultService.isBiometricEnabled();

    if (biometricEnabled) {
      // الحالة 2: خزنة + بصمة → طلب البصمة
      await _authenticateWithBiometric();
    } else {
      // الحالة 3: خزنة بدون بصمة → شاشة Password
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VaultUnlockScreen(),
          ),
        );
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final authenticated = await BiometricService.authenticate();

    if (authenticated && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LockedNotesScreen(),
        ),
      );
    } else if (mounted) {
      // فشلت البصمة → شاشة Password
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const VaultUnlockScreen(
            biometricFailed: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 50,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              l10n.verifyingIdentity,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

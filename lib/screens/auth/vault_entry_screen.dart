// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/screens/auth/locked_notes_intro_screen.dart';
import 'package:apex_note/screens/auth/pin_lock_screen.dart';
import 'package:apex_note/screens/auth/vault_unlock_screen.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/services/security/unified_lock_service.dart';
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
  void dispose() {
    super.dispose();
  }

  Future<void> _checkVaultStatus() async {
    final dbService = IsarDatabaseService();
    final lockedNotes = await dbService.getLockedNotes();
    final hasNewVault = await VaultService.isVaultSetup();

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

    final biometricEnabled = await VaultService.isBiometricEnabled();

    if (biometricEnabled) {
      await _authenticateWithBiometric();
    } else {
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
    // إذا تمت المصادقة مسبقاً عبر قفل التطبيق → دخول مباشر
    if (UnifiedLockService().isAuthenticatedThisSession) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LockedNotesScreen()),
        );
      }
      return;
    }

    final lockType = await UnifiedLockService().getLockType();

    if (lockType == LockType.pin) {
      if (!mounted) return;
      final hasPinAlready = await UnifiedLockService().hasPinSet();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PinLockScreen(
            isSetup: !hasPinAlready,
            autoBiometric: true,
            onSuccess: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LockedNotesScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    final authenticated = await UnifiedLockService().authenticate(context: 'vault_entry');

    if (authenticated && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LockedNotesScreen()),
      );
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const VaultUnlockScreen(biometricFailed: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              isDark ? 'جاري التحقق...' : 'Verifying...',
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

// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/core/utils/vault_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/security/biometric_service.dart';
import 'package:sinan_note/services/security/vault_reset_service.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';

class VaultDialogs {
  static void showSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: AppBottomSheet(
        title: l10n.settings,
        titleIcon: Icons.settings,
        scrollable: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: Text(l10n.createPassword),
              subtitle: const Text('Change vault password'),
              onTap: () {
                Navigator.pop(context);
                showChangePassword(context);
              },
            ),
            FutureBuilder<bool>(
              future: Future.wait([
                VaultService.isBiometricEnabled(),
                BiometricService.hasBiometrics(),
              ]).then((r) => r[1]),
              builder: (context, snapshot) {
                if (snapshot.data != true) return const SizedBox.shrink();
                return FutureBuilder<bool>(
                  future: VaultService.isBiometricEnabled(),
                  builder: (context, biometricSnapshot) {
                    final isEnabled = biometricSnapshot.data ?? false;
                    return SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(l10n.enableBiometric),
                      subtitle: Text(l10n.biometricOptional),
                      value: isEnabled,
                      onChanged: (val) async {
                        await VaultService.setBiometricEnabled(val);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        UnifiedNotificationService().show(
                          context: context,
                          message:
                              val ? 'Biometric enabled' : 'Biometric disabled',
                          type: val
                              ? NotificationType.success
                              : NotificationType.info,
                        );
                      },
                    );
                  },
                );
              },
            ),
            FutureBuilder<bool>(
              future: BiometricService.hasBiometrics(),
              builder: (context, snapshot) {
                if (snapshot.data != true) return const SizedBox.shrink();
                return FutureBuilder<bool>(
                  future: VaultService.isBiometricButtonVisible(),
                  builder: (context, visibleSnapshot) {
                    final isVisible = visibleSnapshot.data ?? true;
                    return SwitchListTile(
                      secondary: const Icon(Icons.visibility_outlined),
                      title: Text(l10n.showBiometricButton),
                      subtitle: Text(l10n.showBiometricButtonDesc),
                      value: isVisible,
                      onChanged: (val) async {
                        await VaultService.setBiometricButtonVisible(val);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: Text(l10n.resetVault),
              subtitle: Text(l10n.resetVaultSubtitle),
              onTap: () {
                Navigator.pop(context);
                VaultNavigator.toReset(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(l10n.destroyVault),
              subtitle: Text(l10n.destroyVaultSubtitle),
              onTap: () {
                Navigator.pop(context);
                _showDestroyVaultDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void _showDestroyVaultDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: AppBottomSheet(
        title: l10n.destroyVault,
        titleIcon: Icons.delete_forever,
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.destroyVaultWarning,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.red[200] : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // خيار 1: فك التشفير ثم تدمير الخزنة
              ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.orange),
                title: Text(l10n.decryptAndDestroy),
                subtitle: Text(l10n.decryptAndDestroyDesc),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDecryptAndDestroy(context);
                },
              ),
              const SizedBox(height: 12),
              // خيار 2: تدمير مع المحتوى
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(l10n.destroyWithContent),
                subtitle: Text(l10n.destroyWithContentDesc),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDestroyWithContent(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static void _confirmDecryptAndDestroy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    bool confirmed = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.decryptAndDestroy),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.decryptAndDestroyConfirm),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: confirmed,
                onChanged: (val) =>
                    setDialogState(() => confirmed = val ?? false),
                title: Text(
                  l10n.confirmDestroyCheckbox,
                  style: const TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: confirmed
                  ? () async {
                      Navigator.pop(ctx);
                      await _authenticateAndExecute(
                        context,
                        () => _executeDecryptAndDestroy(context),
                      );
                    }
                  : null,
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  static void _confirmDestroyWithContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    bool confirmed = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.destroyWithContent),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.destroyWithContentConfirm),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: confirmed,
                onChanged: (val) =>
                    setDialogState(() => confirmed = val ?? false),
                title: Text(
                  l10n.confirmDestroyCheckbox,
                  style: const TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: confirmed
                  ? () async {
                      Navigator.pop(ctx);
                      await _authenticateAndExecute(
                        context,
                        () => _executeDestroyWithContent(context),
                      );
                    }
                  : null,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _authenticateAndExecute(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    VaultResetGuard.isActive = true;
    try {
      await action();
    } finally {
      VaultResetGuard.isActive = false;
    }
  }

  /// تنفيذ تدمير الخزنة — الجزء المشترك بين الخيارين
  /// [processNotes]: دالة تُعالج الملاحظات (فك تشفير أو حذف)
  static Future<void> _executeDestroyVault(
    BuildContext context,
    Future<void> Function(SqliteDatabaseService db, List<dynamic> notes)
        processNotes,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final dbService = SqliteDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();

      if (lockedNotes.isNotEmpty) {
        await processNotes(dbService, lockedNotes);
      }

      await VaultService.clearVault();

      if (!context.mounted) return;

      Provider.of<NotesProvider>(context, listen: false)
          .refreshAllNotes(force: true);

      UnifiedNotificationService().show(
        context: context,
        message: l10n.vaultDestroyed,
        type: NotificationType.success,
      );

      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.settings.name == '/main' || route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: '${l10n.failed}: $e',
        type: NotificationType.error,
      );
    }
  }

  /// فك تشفير كل الملاحظات ثم تدمير الخزنة
  static Future<void> _executeDecryptAndDestroy(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await _executeDestroyVault(context, (db, notes) async {
      enc.Key? masterKey;
      try {
        masterKey = await VaultService.getMasterKey();
      } catch (_) {
        if (!context.mounted) return;
        UnifiedNotificationService().show(
          context: context,
          message: l10n.decryptionFailed,
          type: NotificationType.error,
        );
        return;
      }

      for (final note in notes) {
        final decryptedTitle =
            VaultService.decryptWithKey(note.title, masterKey);
        final decryptedContent =
            VaultService.decryptWithKey(note.content, masterKey);
        await db.updateNote(note.copyWith(
          title: decryptedTitle,
          content: decryptedContent,
          isLocked: false,
          updatedAt: DateTime.now(),
        ));
      }

      VaultService.wipeMasterKey(masterKey);
    });
  }

  /// تدمير الخزنة مع كل محتوياتها
  static Future<void> _executeDestroyWithContent(BuildContext context) async {
    await _executeDestroyVault(context, (db, notes) async {
      for (final note in notes) {
        if (note.id != null) await db.deleteNote(note.id!);
      }
    });
  }

  static void showChangePassword(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true, obscureNew = true, obscureConfirm = true;
    String? errorText;
    bool isLoading = false;

    AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AppBottomSheet(
            title: l10n.createPassword,
            titleIcon: Icons.vpn_key,
            scrollable: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _passwordField(
                    controller: oldCtrl,
                    label: l10n.oldPassword,
                    obscure: obscureOld,
                    onToggle: () =>
                        setModalState(() => obscureOld = !obscureOld),
                    onChanged: () => setModalState(() => errorText = null),
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: newCtrl,
                    label: l10n.newPassword,
                    obscure: obscureNew,
                    onToggle: () =>
                        setModalState(() => obscureNew = !obscureNew),
                    onChanged: () => setModalState(() => errorText = null),
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: confirmCtrl,
                    label: l10n.confirmPassword,
                    obscure: obscureConfirm,
                    onToggle: () =>
                        setModalState(() => obscureConfirm = !obscureConfirm),
                    onChanged: () => setModalState(() => errorText = null),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: l10n.cancel,
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final old = oldCtrl.text;
                                final newP = newCtrl.text;
                                final confirm = confirmCtrl.text;
                                if (old.isEmpty ||
                                    newP.isEmpty ||
                                    confirm.isEmpty) {
                                  setModalState(
                                      () => errorText = l10n.fillAllFields);
                                  return;
                                }
                                if (newP.length < 8) {
                                  setModalState(
                                      () => errorText = 'Minimum 8 characters');
                                  return;
                                }
                                if (!RegExp(r'[0-9]').hasMatch(newP)) {
                                  setModalState(() => errorText =
                                      'Must contain at least one number');
                                  return;
                                }
                                if (!RegExp(
                                        r'[!@#$%^&*()\-_=+\[\]{};:,.<>/?\\|`~"]')
                                    .hasMatch(newP)) {
                                  setModalState(() => errorText =
                                      'Must contain at least one symbol');
                                  return;
                                }
                                if (newP != confirm) {
                                  setModalState(
                                      () => errorText = l10n.passwordMismatch);
                                  return;
                                }
                                setModalState(() => isLoading = true);
                                final success =
                                    await VaultService.changePassword(
                                        old, newP);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  UnifiedNotificationService().show(
                                    context: context,
                                    message: 'Password changed successfully',
                                    type: NotificationType.success,
                                  );
                                } else {
                                  setModalState(() {
                                    isLoading = false;
                                    errorText = l10n.incorrectPassword;
                                  });
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded),
                        tooltip: l10n.save,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required VoidCallback onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

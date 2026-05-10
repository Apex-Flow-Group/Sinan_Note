// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/auth/vault_intro_pages.dart';
import 'package:apex_note/services/security/vault_reset_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/copy_code_button.dart';
import 'package:flutter/material.dart';

/// شاشة إعادة تعيين تشفير الخزنة (Wizard)
/// الخطوات:
/// 1. تحقق بالبصمة
/// 2. تحذير: أنشئ نسخة احتياطية
/// 3. إنشاء كلمة مرور جديدة
/// 4. تحذير: لا تغلق التطبيق + تنفيذ العملية
/// 5. عرض كود الاسترداد الجديد
class VaultResetScreen extends StatefulWidget {
  const VaultResetScreen({super.key});

  @override
  State<VaultResetScreen> createState() => _VaultResetScreenState();
}

enum _ResetStep {
  warning,
  newPassword,
  processing,
  showRecoveryCode,
}

class _VaultResetScreenState extends State<VaultResetScreen> {
  _ResetStep _currentStep = _ResetStep.warning;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _passwordError;

  // حالة العملية
  VaultResetProgress _progress = const VaultResetProgress(
    status: VaultResetStatus.idle,
  );
  StreamSubscription<VaultResetProgress>? _progressSub;
  String? _newRecoveryCode;
  bool _codeSaved = false;

  @override
  void dispose() {
    // إعادة تفعيل حماية الخزنة عند الخروج
    VaultResetGuard.isActive = false;
    _progressSub?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _authenticateAndProceed() async {
    VaultResetGuard.isActive = true;
    final password = await _showPasswordDialog();
    if (password == null) {
      VaultResetGuard.isActive = false;
      return;
    }
    final authenticated = await VaultService.verifyPassword(password);
    if (!mounted) {
      VaultResetGuard.isActive = false;
      return;
    }
    if (authenticated) {
      setState(() => _currentStep = _ResetStep.newPassword);
    } else {
      VaultResetGuard.isActive = false;
      UnifiedNotificationService().show(
        context: context,
        message: AppLocalizations.of(context)!.wrongPassword,
        type: NotificationType.error,
      );
    }
  }

  Future<String?> _showPasswordDialog() async {
    final ctrl = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(AppLocalizations.of(ctx)!.enterVaultPassword),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            autofocus: true,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => set(() => obscure = !obscure),
              ),
            ),
            onSubmitted: (_) => Navigator.pop(ctx, ctrl.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(AppLocalizations.of(ctx)!.confirm),
            ),
          ],
        ),
      ),
    );
  }

  void _startReset() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // التحقق من كلمة المرور
    final validationError = validateVaultPassword(password);
    if (validationError != null) {
      setState(() => _passwordError = validationError);
      return;
    }
    if (password != confirm) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }

    setState(() {
      _currentStep = _ResetStep.processing;
      _passwordError = null;
    });

    // بدء العملية بعد رسم الـ UI
    final service = VaultResetService();
    _progressSub = service.progressStream.listen((progress) {
      if (!mounted) return;
      setState(() => _progress = progress);

      if (progress.status == VaultResetStatus.completed) {
        setState(() {
          _newRecoveryCode = progress.newRecoveryCode;
          _currentStep = _ResetStep.showRecoveryCode;
        });
      } else if (progress.status == VaultResetStatus.failed) {
        // العودة لخطوة كلمة المرور مع عرض الخطأ
        setState(() {
          _currentStep = _ResetStep.newPassword;
          _passwordError = progress.errorMessage;
        });
      }
    });

    // تأخير بسيط لضمان رسم شاشة التقدم قبل بدء العملية الثقيلة
    Future.delayed(const Duration(milliseconds: 100), () {
      service.executeReset(newPassword: password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _currentStep != _ResetStep.processing,
      child: Scaffold(
        appBar: _currentStep == _ResetStep.processing
            ? null
            : AppBar(
                title: Text(l10n.resetVault),
                centerTitle: true,
                leading: _currentStep == _ResetStep.showRecoveryCode
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                automaticallyImplyLeading: false,
              ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(isDark, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark, AppLocalizations l10n) {
    switch (_currentStep) {
      case _ResetStep.warning:
        return _WarningStep(
          isDark: isDark,
          l10n: l10n,
          onProceed: _authenticateAndProceed,
        );
      case _ResetStep.newPassword:
        return Column(
          children: [
            Expanded(
              child: VaultPasswordPage(
                isDark: isDark,
                passwordController: _passwordController,
                confirmController: _confirmController,
                obscurePassword: _obscurePassword,
                obscureConfirm: _obscureConfirm,
                errorText: _passwordError,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onToggleConfirm: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                onChanged: () => setState(() => _passwordError = null),
                onSubmit: _startReset,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.resetVaultDoNotClose,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.amber[200]
                                  : Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _passwordController.text.length >= 8 &&
                              _confirmController.text.length >= 8
                          ? _startReset
                          : null,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.startReset),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _ResetStep.processing:
        return _ProcessingStep(isDark: isDark, l10n: l10n, progress: _progress);
      case _ResetStep.showRecoveryCode:
        return _RecoveryCodeStep(
          isDark: isDark,
          l10n: l10n,
          recoveryCode: _newRecoveryCode ?? '',
          codeSaved: _codeSaved,
          onCodeSavedChanged: (val) =>
              setState(() => _codeSaved = val ?? false),
          onDone: () {
            if (!_codeSaved) {
              UnifiedNotificationService().show(
                context: context,
                message: l10n.saveCodeFirst,
                type: NotificationType.warning,
              );
              return;
            }
            Navigator.pop(context, true);
          },
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// الخطوة 1: تحذير + تحقق بالبصمة
// ═══════════════════════════════════════════════════════════════════════════════

class _WarningStep extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onProceed;

  const _WarningStep({
    required this.isDark,
    required this.l10n,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.warning_amber, size: 50, color: Colors.orange),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.resetVaultWarningTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.resetVaultWarningBody,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.resetVaultBackupHint,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.red[200] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onProceed,
              icon: const Icon(Icons.lock_outline),
              label: Text(l10n.enterVaultPassword),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// الخطوة 3: العملية جارية (لا يمكن الخروج)
// ═══════════════════════════════════════════════════════════════════════════════

class _ProcessingStep extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  final VaultResetProgress progress;

  const _ProcessingStep({
    required this.isDark,
    required this.l10n,
    required this.progress,
  });

  String _statusText(AppLocalizations l10n) {
    switch (progress.status) {
      case VaultResetStatus.backingUp:
        return l10n.resetStatusBackingUp;
      case VaultResetStatus.decrypting:
        return l10n.resetStatusDecrypting;
      case VaultResetStatus.generatingNewKey:
        return l10n.resetStatusGeneratingKey;
      case VaultResetStatus.reEncrypting:
        return l10n.resetStatusReEncrypting;
      case VaultResetStatus.replacingDatabase:
        return l10n.resetStatusReplacing;
      default:
        return l10n.resetStatusPreparing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _statusText(l10n),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (progress.totalNotes > 0) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              color: Colors.deepPurple,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            Text(
              '${progress.processedNotes} / ${progress.totalNotes}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.do_not_disturb, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.resetVaultDoNotClose,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.red[200] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// الخطوة 4: عرض كود الاسترداد الجديد
// ═══════════════════════════════════════════════════════════════════════════════

class _RecoveryCodeStep extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  final String recoveryCode;
  final bool codeSaved;
  final ValueChanged<bool?> onCodeSavedChanged;
  final VoidCallback onDone;

  const _RecoveryCodeStep({
    required this.isDark,
    required this.l10n,
    required this.recoveryCode,
    required this.codeSaved,
    required this.onCodeSavedChanged,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_circle, size: 50, color: Colors.green),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.resetVaultSuccess,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.recoveryCode,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Text(
              recoveryCode,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          CopyCodeButton(
            code: recoveryCode,
            label: l10n.copyCode,
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: codeSaved,
            onChanged: onCodeSavedChanged,
            title: Text(l10n.iHaveSavedCode),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.done),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

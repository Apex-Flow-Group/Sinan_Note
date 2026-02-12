// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../../services/security/vault_service.dart';

class RecoveryCodeDialog extends StatefulWidget {
  const RecoveryCodeDialog({super.key});

  @override
  State<RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<RecoveryCodeDialog> {
  final _recoveryController = TextEditingController();
  String? _errorText;
  bool _isVerifying = false;

  @override
  void dispose() {
    _recoveryController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    final recoveryCode = _recoveryController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (recoveryCode.isEmpty) {
      setState(() => _errorText = l10n.enterRecoveryCode);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      // Verify and unlock with recovery code
      final success = await VaultService.recoverWithCode(recoveryCode);
      
      if (success && mounted) {
        // ✅ Mark vault as unlocked in session
        await VaultService.markVaultUnlocked();
        Navigator.pop(context, true); // Success
      } else {
        setState(() {
          _errorText = l10n.invalidRecoveryCode;
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Error: $e';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.vpn_key, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.recoveryCode,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enterRecoveryCode,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _recoveryController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'SN-XXXX-XXXX-XXXX',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  letterSpacing: 1,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                prefixIcon: const Icon(Icons.vpn_key, color: Colors.orange),
              ),
              onChanged: (_) => setState(() => _errorText = null),
              onSubmitted: (_) => _handleRecover(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'هذا هو الرقم الطويل الذي حصلت عليه عند إنشاء الخزنة'
                          : 'This is the long code you received when creating the vault',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _isVerifying ? null : _handleRecover,
          icon: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.lock_open),
          label: Text(
            _isVerifying ? '...' : l10n.unlock,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

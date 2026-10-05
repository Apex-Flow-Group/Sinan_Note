// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/vault/view_models/vault_view_model.dart';

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

    final success = await context
        .read<VaultViewModel>()
        .unlockWithRecoveryCode(recoveryCode);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorText = l10n.invalidRecoveryCode;
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.vpn_key, color: context.colors.vault),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.recoveryCode,
              style: context.text.headlineSmall,
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
              style: context.text.bodyMedium
                  ?.copyWith(color: context.scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _recoveryController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: l10n.recoveryCodeFormatHint,
                hintStyle: TextStyle(
                  color: context.colors.muted,
                  letterSpacing: 1,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.vault, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: context.scheme.outlineVariant, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.vault, width: 2),
                ),
                prefixIcon: Icon(Icons.vpn_key, color: context.colors.vault),
              ),
              onChanged: (_) => setState(() => _errorText = null),
              onSubmitted: (_) => _handleRecover(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.scheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.scheme.error, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: context.scheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.scheme.error),
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
                color: context.colors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: context.colors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.recoveryCodeOriginHint,
                      style: context.text.labelMedium,
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
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.colors.onVault),
                )
              : const Icon(Icons.lock_open),
          label: Text(
            _isVerifying ? '...' : l10n.unlock,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.vault,
            foregroundColor: context.colors.onVault,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

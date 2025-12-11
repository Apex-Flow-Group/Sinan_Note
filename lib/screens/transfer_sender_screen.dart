// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../services/local_server_service.dart';
import '../services/backup_service.dart';

class TransferSenderScreen extends StatefulWidget {
  const TransferSenderScreen({super.key});

  @override
  State<TransferSenderScreen> createState() => _TransferSenderScreenState();
}

class _TransferSenderScreenState extends State<TransferSenderScreen> {
  final LocalServerService _serverService = LocalServerService();
  final BackupService _backupService = BackupService();
  String? _serverUrl;
  String? _securityToken;
  bool _isLoading = true;
  String? _errorMessage;
  int _lockedNotesCount = 0;
  String? _tempDbPath;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      final (tempDbPath, lockedCount) =
          await _backupService.prepareSanitizedDatabase();
      _tempDbPath = tempDbPath;
      _lockedNotesCount = lockedCount;

      final dbFile = File(tempDbPath);
      _serverUrl = await _serverService.startFileServer(dbFile);
      _securityToken = _serverService.securityToken;

      setState(() => _isLoading = false);

      if (_lockedNotesCount > 0 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLockedNotesWarning();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showLockedNotesWarning() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        icon: const Icon(Icons.lock, color: Colors.orange, size: 40),
        title: Text(l10n.securityAlert),
        content: Text(
          '${l10n.lockedNotesCount(_lockedNotesCount)}\n'
          '${l10n.wontTransferForSecurity}\n\n'
          '${l10n.openVaultTab}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  String _extractIpFromUrl(String url) {
    return url.replaceAll('http://', '').split(':').first;
  }

  Future<void> _handleExit() async {
    await _serverService.stopServer();
    if (_tempDbPath != null) {
      _backupService.cleanupSanitizedDatabase();
    }
  }

  @override
  void dispose() {
    _serverService.stopServer();
    if (_tempDbPath != null) {
      _backupService.cleanupSanitizedDatabase();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          await _handleExit();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.sendNotes),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _handleExit();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.verifyingIdentity,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            l10n.transferError,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.scanQrCode,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _serverUrl!,
                            version: QrVersions.auto,
                            size: 280,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.blue[900]!,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.blue[900]!,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildInfoCard(
                          icon: Icons.router,
                          title: 'IP Address',
                          value: _extractIpFromUrl(_serverUrl!),
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.security,
                          title: 'Security Code',
                          value: _securityToken!,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.amber, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Keep screen open',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.amber[900]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

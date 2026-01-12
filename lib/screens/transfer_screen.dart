// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'main_layout_screen.dart';
import '../services/settings_provider.dart';
import '../services/notes_provider.dart';
import '../services/transfer_client_service.dart';
import '../services/database_service.dart';
import '../models/transfer_status.dart';
import 'transfer_screen_helper.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransferState _state = TransferState(status: TransferStatus.idle);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSenderScreen() async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    final lockedCount = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
        0;

    if (lockedCount > 0) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final systemLocale =
          View.of(context).platformDispatcher.locale.languageCode;
      final currentLang = settings.languageCode == 'system'
          ? systemLocale
          : settings.languageCode;

      final agreed = await TransferAgreementDialog.show(
          context, currentLang == 'ar', lockedCount);
      if (agreed != true) return;
    }

    Navigator.pushNamed(context, '/transfer_sender');
  }

  void _openReceiverScreen() async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    final lockedCount = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
        0;

    if (lockedCount > 0) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final systemLocale =
          View.of(context).platformDispatcher.locale.languageCode;
      final currentLang = settings.languageCode == 'system'
          ? systemLocale
          : settings.languageCode;

      final agreed = await TransferAgreementDialog.show(
          context, currentLang == 'ar', lockedCount);
      if (agreed != true) return;
    }

    Navigator.pushNamed(context, '/transfer_connect');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final isArabic = currentLang == 'ar';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.transferTitle),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: const Icon(Icons.upload), text: l10n.send),
              Tab(icon: const Icon(Icons.download), text: l10n.receive),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSenderTab(l10n, isArabic),
                  _buildReceiverTab(l10n, isArabic),
                ],
              ),
            ),
            _buildAgreementButton(l10n, isArabic),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderTab(
      AppLocalizations l10n, bool isArabic) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final notes = notesProvider.activeNotes;

        if (notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  Text(
                    l10n.noNotesToShare,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.createNoteFirst,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const MainLayoutScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createNote),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_android, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  l10n.oldPhone,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.tapButtonToShare,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _openSenderScreen,
                  icon: const Icon(Icons.qr_code),
                  label: Text(l10n.startSending),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualEntryDialog(AppLocalizations l10n, bool isArabic) async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    final lockedCount = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
        0;

    if (lockedCount > 0) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final systemLocale =
          View.of(context).platformDispatcher.locale.languageCode;
      final currentLang = settings.languageCode == 'system'
          ? systemLocale
          : settings.languageCode;

      final agreed = await TransferAgreementDialog.show(
          context, currentLang == 'ar', lockedCount);
      if (agreed != true) return;
    }

    final ip1Controller = TextEditingController();
    final ip2Controller = TextEditingController();
    final ip3Controller = TextEditingController();
    final ip4Controller = TextEditingController();
    final tokenController = TextEditingController();

    _loadDefaultIp(ip1Controller, ip2Controller, ip3Controller);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.manualEntry),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIpField(ip1Controller, 3),
                      const Text('.', style: TextStyle(fontSize: 20)),
                      _buildIpField(ip2Controller, 3),
                      const Text('.', style: TextStyle(fontSize: 20)),
                      _buildIpField(ip3Controller, 3),
                      const Text('.', style: TextStyle(fontSize: 20)),
                      _buildIpField(ip4Controller, 3),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenController,
                    decoration: InputDecoration(
                      labelText: l10n.securityCode,
                      hintText: 'ABC123',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                        );
                      }),
                    ],
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final ip =
                  '${ip1Controller.text}.${ip2Controller.text}.${ip3Controller.text}.${ip4Controller.text}';
              final token = tokenController.text.trim().toUpperCase();
              if (ip4Controller.text.isNotEmpty && token.isNotEmpty) {
                Navigator.pop(ctx);
                _handleQrCode('http://$ip:8765/download-db?token=$token');
              }
            },
            child: Text(l10n.connect),
          ),
        ],
      ),
    );
  }

  Widget _buildIpField(TextEditingController controller, int maxLength) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: maxLength,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _loadDefaultIp(TextEditingController ip1,
      TextEditingController ip2, TextEditingController ip3) async {
    try {
      final interfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.contains('.')) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              ip1.text = parts[0];
              ip2.text = parts[1];
              ip3.text = parts[2];
              return;
            }
          }
        }
      }
    } catch (e) {
      ip1.text = '192';
      ip2.text = '168';
      ip3.text = '1';
    }
  }

  void _handleQrCode(String code) async {
    if (_state.status == TransferStatus.transferring) return;

    setState(() {
      _state = TransferState(
          status: TransferStatus.connecting, message: 'Connecting...');
    });

    try {
      final uri = Uri.parse(code);
      final host = uri.host;
      final port = uri.port.toString();
      final token = uri.queryParameters['token'] ?? '';

      final client = TransferClientService();
      final localCount = await client.checkLocalNotesCount();

      setState(() => _state = TransferState(
          status: TransferStatus.transferring,
          message: 'Downloading...',
          progress: 0));

      await client.downloadToTemp(
        host,
        port,
        token,
        onProgress: (progress) {
          setState(() => _state = _state.copyWith(progress: progress));
        },
      );

      if (localCount > 0) {
        final l10n = AppLocalizations.of(context)!;
        await _showMergeDialog(l10n, localCount);
      } else {
        await client.replaceWithIncoming();
        await DatabaseService().reopenDatabase();
        if (mounted) {
          await Provider.of<NotesProvider>(context, listen: false)
              .refreshAllNotes();
        }
        setState(() => _state = TransferState(
            status: TransferStatus.completed, message: 'Transfer completed!'));
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      setState(() => _state =
          TransferState(status: TransferStatus.error, message: e.toString()));
    }
  }

  Future<void> _showMergeDialog(AppLocalizations l10n, int localCount) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final isArabic = currentLang == 'ar';

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dataConflict),
        content: Text(
          isArabic
              ? 'يحتوي هذا الجهاز على $localCount ملاحظة.\nكيف تريد المتابعة?'
              : 'This device has $localCount notes.\nHow do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: Text(l10n.merge),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: Text(l10n.replace),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') {
      setState(() => _state = TransferState(status: TransferStatus.idle));
      return;
    }

    try {
      final client = TransferClientService();
      if (choice == 'merge') {
        await client.mergeDatabase();
      } else {
        await client.replaceWithIncoming();
        await DatabaseService().reopenDatabase();
      }

      if (mounted) {
        await Provider.of<NotesProvider>(context, listen: false)
            .refreshAllNotes();
      }

      setState(() => _state = TransferState(
          status: TransferStatus.completed, message: 'Completed!'));
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      setState(() => _state =
          TransferState(status: TransferStatus.error, message: e.toString()));
    }
  }

  Widget _buildAgreementButton(AppLocalizations l10n, bool isArabic) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
      ),
      child: TextButton.icon(
        onPressed: () async {
          final dbService = DatabaseService();
          final db = await dbService.database;
          final lockedCount = Sqflite.firstIntValue(await db
                  .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
              0;

          if (lockedCount > 0) {
            await TransferAgreementDialog.show(context, isArabic, lockedCount);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.noLockedNotes),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        icon: const Icon(Icons.check_circle_outline,
            color: Colors.blue, size: 18),
        label: Text(
          l10n.viewTransferPolicy,
          style: const TextStyle(color: Colors.blue, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildReceiverTab(
      AppLocalizations l10n, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_iphone, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              l10n.newPhone,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseConnectionMethod,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openReceiverScreen,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.scanQrCode),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _showManualEntryDialog(l10n, isArabic);
              },
              icon: const Icon(Icons.keyboard),
              label: Text(l10n.manualEntry),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

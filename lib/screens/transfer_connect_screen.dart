// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../services/transfer_client_service.dart';
import '../services/database_service.dart';

class TransferConnectScreen extends StatefulWidget {
  const TransferConnectScreen({super.key});

  @override
  State<TransferConnectScreen> createState() => _TransferConnectScreenState();
}

class _TransferConnectScreenState extends State<TransferConnectScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  final GlobalKey _scannerKey = GlobalKey(debugLabel: 'QR');
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  TransferClientService? _client;
  bool _isManualMode = false;
  bool _isProcessing = false;
  bool _torchOn = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isManualMode && _isPermissionGranted) {
      if (state == AppLifecycleState.resumed) {
        _controller.start();
      } else if (state == AppLifecycleState.paused) {
        _controller.stop();
      }
    }
    if (state == AppLifecycleState.detached) {
      _client?.cancelTransfer();
    }
  }

  Future<void> _checkCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() => _isPermissionGranted = true);
      return;
    }

    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      setState(() => _isProcessing = true);
      _controller.stop();
      _connectToPeer(code);
    }
  }

  Future<void> _connectToPeer(String ip) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final parts = ip.split(':');
      final host = parts[0];
      final port = parts.length > 1 ? parts[1] : '8765';
      final token = parts.length > 2 ? parts[2] : '';

      _client = TransferClientService();
      await _client!.downloadToTemp(host, port, token, onProgress: (_) {});
      await _client!.replaceWithIncoming();
      await DatabaseService().reopenDatabase();

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.transferSuccess)),
      );
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      navigator.pop();
      final l10n = AppLocalizations.of(context)!;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('${l10n.transferError}: $e')),
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        _controller.start();
      }
    }
  }

  void _toggleTorch() {
    setState(() => _torchOn = !_torchOn);
    _controller.toggleTorch();
  }

  void _connectManually() {
    final ip = _ipController.text.trim();
    final token = _tokenController.text.trim();
    
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterIP)),
      );
      return;
    }
    
    final connectionString = '$ip:8765:$token';
    _connectToPeer(connectionString);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _ipController.dispose();
    _tokenController.dispose();
    _client?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.connectToDevice)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.requestingCameraPermission),
              const SizedBox(height: 24),
              if (Platform.isAndroid || Platform.isIOS)
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  child: Text(l10n.openSettings),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connectToDevice),
        actions: [
          IconButton(
            icon: Icon(_isManualMode ? Icons.qr_code_scanner : Icons.keyboard),
            onPressed: () => setState(() => _isManualMode = !_isManualMode),
          ),
        ],
      ),
      body: _isManualMode ? _buildManualEntry() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          key: _scannerKey,
          controller: _controller,
          onDetect: _onDetect,
        ),
        // Overlay with scanning box
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Instructions
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Scan QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10, color: Colors.black)],
              ),
            ),
          ),
        ),
        // Torch button
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: IconButton(
              icon: Icon(
                _torchOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 32,
              ),
              onPressed: _toggleTorch,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntry() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Manual Connection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Security Token (Optional)',
                hintText: 'Leave empty if no security',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connectManually,
              icon: const Icon(Icons.link),
              label: Text(l10n.connect),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

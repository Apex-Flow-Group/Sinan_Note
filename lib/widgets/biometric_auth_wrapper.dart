// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../services/biometric_service.dart';
import '../services/settings_provider.dart';
import '../services/notes_provider.dart';

/// Wrapper that handles global app lock with biometric authentication
/// Monitors app lifecycle and triggers auth when app resumes from background
class BiometricAuthWrapper extends StatefulWidget {
  final Widget child;

  const BiometricAuthWrapper({super.key, required this.child});

  @override
  State<BiometricAuthWrapper> createState() => _BiometricAuthWrapperState();
}

class _BiometricAuthWrapperState extends State<BiometricAuthWrapper>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  bool _showPrivacy = false;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSecurity();
  }

  Future<void> _initSecurity() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.ensureInitialized();

    if (settings.isAppLockEnabled) {
      _isAuthenticated = false;
      _requireAuthentication();
    } else {
      _isAuthenticated = true;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    // CASE 1: PAUSED/INACTIVE - Going to Background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        // Controller: ONLY hideContentInBackground (for Recents)
        _showPrivacy = settings.hideContentInBackground;
        
        // Lock app if enabled
        if (settings.isAppLockEnabled) {
          _backgroundTime = DateTime.now();
          _isAuthenticated = false;
        }
      });
      notesProvider.lockVault();
    }

    // CASE 2: RESUMED - Coming to Foreground
    if (state == AppLifecycleState.resumed) {
      // ALWAYS hide privacy overlay first (for Recents dimming)
      setState(() => _showPrivacy = false);
      
      // Then handle biometric lock separately
      if (settings.isAppLockEnabled) {
        // Check lock delay
        bool skipAuth = false;
        if (settings.lockDelayEnabled && _backgroundTime != null) {
          final elapsed = DateTime.now().difference(_backgroundTime!).inSeconds;
          if (elapsed < settings.lockDelaySeconds) {
            skipAuth = true;
          }
        }
        
        if (skipAuth) {
          setState(() => _isAuthenticated = true);
        } else if (!_isAuthenticating) {
          // Show lock screen (different from privacy overlay)
          _requireAuthentication();
        }
      }
    }
  }

  Future<void> _requireAuthentication() async {
    if (_isAuthenticating || !mounted) return;

    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await BiometricService.authenticate();

      if (!mounted) return;
      setState(() {
        _isAuthenticated = authenticated;
        _showPrivacy = !authenticated; // Hide only on success
      });
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.note_alt_outlined,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sinan Note',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final settings = Provider.of<SettingsProvider>(context);

    if (settings.isAppLockEnabled && !_isAuthenticated) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black87,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.note_alt_outlined,
                        size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sinan Note',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Icon(Icons.lock, size: 60, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    l10n.secureVault,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.verifyingIdentity,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.unlock),
                    onPressed: _requireAuthentication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        widget.child,
        if (_showPrivacy)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.note_alt_outlined,
                            size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sinan Note',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

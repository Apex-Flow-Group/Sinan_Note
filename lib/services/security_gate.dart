// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'biometric_service.dart';
import '../screens/lock_screen.dart';

/// Immutable security configuration
class SecurityConfig {
  final bool lockEnabled;
  final int lockDelaySeconds;
  final bool privacyBlurEnabled;

  const SecurityConfig({
    required this.lockEnabled,
    required this.lockDelaySeconds,
    required this.privacyBlurEnabled,
  });
}

/// Singleton Security Controller - Black Box Pattern
class SecurityController extends ChangeNotifier with WidgetsBindingObserver {
  static final SecurityController _instance = SecurityController._internal();
  factory SecurityController() => _instance;
  SecurityController._internal();

  static const _platform = MethodChannel('com.apexflow.app.sinan/security');

  SecurityConfig _config = const SecurityConfig(
    lockEnabled: false,
    lockDelaySeconds: 0,
    privacyBlurEnabled: false,
  );

  bool _isLocked = false;
  bool _isAuthenticating = false;
  DateTime? _pausedTime;

  bool get isLocked => _isLocked;
  bool get isAuthenticating => _isAuthenticating;

  bool _isInitialized = false;

  void initialize(SecurityConfig config) {
    _config = config;
    debugPrint('🔴 GATE: initialize() called - Lock: ${config.lockEnabled}, Delay: ${config.lockDelaySeconds}s, Privacy: ${config.privacyBlurEnabled}');
    
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      debugPrint('🔴 GATE: Lifecycle observer registered ✅');
    }
    
    // Initial lock state on app start
    if (_config.lockEnabled) {
      _isLocked = true;
      notifyListeners();
      debugPrint('🔴 GATE: App locked on startup');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔴 GATE: Lifecycle State Changed to: $state');

    switch (state) {
      case AppLifecycleState.paused:
        _handlePause();
        break;
      case AppLifecycleState.inactive:
        _handleInactive();
        break;
      case AppLifecycleState.resumed:
        _handleResume();
        break;
      default:
        break;
    }
  }

  void _handleInactive() {
    debugPrint('🔴 GATE: Inactive... Privacy Enabled? ${_config.privacyBlurEnabled}');
    
    // Enable native FLAG_SECURE for Recents screen (independent of lock)
    if (_config.privacyBlurEnabled) {
      debugPrint('🔴 GATE: Enabling FLAG_SECURE for privacy');
      _setSecureFlag(true);
    }
  }

  void _handlePause() {
    debugPrint('🔴 GATE: Paused (app in background)');
    
    // Save pause time for lock calculation (only if lock is enabled and not already paused)
    if (_config.lockEnabled && _pausedTime == null) {
      _pausedTime = DateTime.now();
      debugPrint('🔴 GATE: Saving pause time: $_pausedTime (delay: ${_config.lockDelaySeconds}s)');
    }
  }

  void _handleResume() {
    debugPrint('🔴 GATE: Resuming...');
    
    // Disable native FLAG_SECURE (always, independent of lock)
    debugPrint('🔴 GATE: Disabling FLAG_SECURE');
    _setSecureFlag(false);

    // Lock logic (only if lock is enabled and we have a pause time)
    if (_config.lockEnabled && _pausedTime != null) {
      final elapsed = DateTime.now().difference(_pausedTime!).inSeconds;
      debugPrint('🔴 GATE: Time Difference: $elapsed seconds. Limit: ${_config.lockDelaySeconds}s');
      
      // Lock if elapsed time >= delay (0 means immediate lock)
      if (elapsed >= _config.lockDelaySeconds) {
        _isLocked = true;
        debugPrint('🔴 GATE: Lock triggered (elapsed: ${elapsed}s >= delay: ${_config.lockDelaySeconds}s)');
        
        notifyListeners();
        
        // Trigger biometric authentication
        if (!_isAuthenticating) {
          debugPrint('🔴 GATE: Triggering biometric authentication');
          _authenticate();
        }
      } else {
        debugPrint('🔴 GATE: No lock (elapsed: ${elapsed}s < delay: ${_config.lockDelaySeconds}s)');
      }
    } else if (_config.lockEnabled) {
      debugPrint('🔴 GATE: Lock enabled but no pause time recorded');
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;
    notifyListeners();

    try {
      final authenticated = await BiometricService.authenticate();
      
      if (authenticated) {
        _isLocked = false;
        _pausedTime = null;
      }
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Manual unlock trigger (for UI button)
  Future<void> requestUnlock() async {
    await _authenticate();
  }

  /// Manual lock trigger (for logout/settings)
  void lock() {
    _isLocked = true;
    _pausedTime = DateTime.now();
    notifyListeners();
  }

  /// Update configuration at runtime
  void updateConfig(SecurityConfig config) {
    debugPrint('🔴 GATE: Config Updated -> Lock: ${config.lockEnabled}, Delay: ${config.lockDelaySeconds}s, Privacy: ${config.privacyBlurEnabled}');
    final bool lockWasEnabled = _config.lockEnabled;
    _config = config;
    
    // Only unlock if lock was disabled (not for privacy/timer changes)
    if (lockWasEnabled && !_config.lockEnabled) {
      _isLocked = false;
      notifyListeners();
      debugPrint('🔴 GATE: Lock disabled, unlocking app');
    }
    // Don't trigger any authentication for privacy/timer changes
  }

  /// Set native FLAG_SECURE
  Future<void> _setSecureFlag(bool secure) async {
    debugPrint('🔴 GATE: Sending Native Command: secure=$secure');
    try {
      final result = await _platform.invokeMethod('secureScreen', {'secure': secure});
      debugPrint('🔴 GATE: Native response: $result ✅');
    } on PlatformException catch (e) {
      debugPrint('🔴 GATE: ❌ Native call FAILED: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('🔴 GATE: ❌ Unexpected error: $e');
    }
  }
}

/// Security Gate Widget - Wraps entire app
class SecurityGate extends StatelessWidget {
  final Widget child;
  final SecurityController controller;

  const SecurityGate({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLocked) {
          return const LockScreen();
        }
        return child;
      },
    );
  }
}



// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/services/security/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  SecurityConfig get config => _config; // Expose for deduplication check

  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _ignoreLifecycle = false; // 🔇 Silencing flag
  DateTime? _pausedTime;

  bool get isLocked => _isLocked;
  bool get isAuthenticating => _isAuthenticating;

  bool _isInitialized = false;

  void initialize(SecurityConfig config) {
    _config = config;
    
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }
    
    // Initial lock state on app start
    if (_config.lockEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔇 SILENCE: Ignore all lifecycle events during biometric authentication
    if (_ignoreLifecycle) {
      return;
    }

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
    // Enable native FLAG_SECURE for Recents screen (independent of lock)
    if (_config.privacyBlurEnabled) {
      _setSecureFlag(true);
    }
  }

  void _handlePause() {
    // ✅ Ignore pause events during biometric authentication
    if (_isAuthenticating || _ignoreLifecycle) {
      return;
    }
    
    // Save pause time for lock calculation
    if (_config.lockEnabled && _pausedTime == null) {
      _pausedTime = DateTime.now();
    }
  }

  void _handleResume() {
    // Disable native FLAG_SECURE (always, independent of lock)
    _setSecureFlag(false);

    // 1. ✅ Ignore resume events during biometric authentication
    if (_isAuthenticating) {
      return;
    }

    // 2. If lock is enabled and we have pause time, trigger lock
    if (_config.lockEnabled && _pausedTime != null) {
      final elapsed = DateTime.now().difference(_pausedTime!).inSeconds;

      if (elapsed >= _config.lockDelaySeconds) {
        _isLocked = true;
        notifyListeners();
      }
    }
    
    // Clean up pause time
    _pausedTime = null;
  }

  Future<void> _authenticate() async {
    // 🛡️ Guard Clause #1: Already unlocked? Don't authenticate again!
    if (!_isLocked) {
      return;
    }

    // 🛡️ Guard Clause #2: Already authenticating?
    if (_isAuthenticating) {
      return;
    }

    _isAuthenticating = true;
    _ignoreLifecycle = true; // 🔇 MUTE: Silence lifecycle listener
    notifyListeners();

    try {
      final authenticated = await BiometricService.authenticate();
      
      if (authenticated) {
        _isLocked = false;
        _pausedTime = null;
        
        // 🚀 INSTANT DISMISSAL: Update UI immediately to hide lock screen
        notifyListeners();
      }
    } catch (e) {
      // Silent error
    } finally {
      _isAuthenticating = false;
      
      // 🔇 Safety period: Keep silencing for 500ms in background
      await Future.delayed(const Duration(milliseconds: 500));
      
      _ignoreLifecycle = false; // 🔊 UNMUTE: Re-enable lifecycle listener
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
    final bool wasLockEnabled = _config.lockEnabled;
    _config = config;

    // Unlock if switching from ON to OFF
    if (!config.lockEnabled && wasLockEnabled) {
      _isLocked = false;
      _pausedTime = null;
      notifyListeners();
    }
  }

  /// Set native FLAG_SECURE
  Future<void> _setSecureFlag(bool secure) async {
    if (!_isAndroid()) return;
    
    try {
      await _platform.invokeMethod('secureScreen', {'secure': secure});
    } catch (e) {
      // Silent error
    }
  }
  
  bool _isAndroid() {
    try {
      return Theme.of(WidgetsBinding.instance.rootElement!).platform == TargetPlatform.android;
    } catch (e) {
      return false;
    }
  }
}





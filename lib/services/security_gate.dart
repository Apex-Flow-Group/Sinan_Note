// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'biometric_service.dart';

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

    // 🔇 SILENCE: Ignore all lifecycle events during biometric authentication
    if (_ignoreLifecycle) {
      debugPrint('🔇 GATE: Lifecycle IGNORED (Silenced during auth)');
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
    debugPrint('🔴 GATE: Inactive... Privacy Enabled? ${_config.privacyBlurEnabled}');
    
    // Enable native FLAG_SECURE for Recents screen (independent of lock)
    if (_config.privacyBlurEnabled) {
      debugPrint('🔴 GATE: Enabling FLAG_SECURE for privacy');
      _setSecureFlag(true);
    }
  }

  void _handlePause() {
    debugPrint('🔴 GATE: Paused (app in background)');
    
    // ✅ Ignore pause events during biometric authentication
    if (_isAuthenticating || _ignoreLifecycle) {
      debugPrint('🔴 GATE: Ignoring pause (biometric in progress)');
      return;
    }
    
    // Save pause time for lock calculation
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

    // 1. ✅ Ignore resume events during biometric authentication
    if (_isAuthenticating) {
      debugPrint('🔴 GATE: Ignoring resume (Auth in progress)');
      return;
    }

    // 2. If lock is enabled and we have pause time, trigger lock
    if (_config.lockEnabled && _pausedTime != null) {
      final elapsed = DateTime.now().difference(_pausedTime!).inSeconds;
      debugPrint('🔴 GATE: Elapsed time: $elapsed seconds. Limit: ${_config.lockDelaySeconds}s');

      if (elapsed >= _config.lockDelaySeconds) {
        _isLocked = true;
        debugPrint('🔴 GATE: Lock triggered - will show SplashScreen');
        notifyListeners();
      }
    }
    
    // Clean up pause time
    _pausedTime = null;
  }

  Future<void> _authenticate() async {
    // 🛡️ Guard Clause #1: Already unlocked? Don't authenticate again!
    if (!_isLocked) {
      debugPrint('⚠️ GATE: Auth blocked (Already Unlocked)');
      return;
    }

    // 🛡️ Guard Clause #2: Already authenticating?
    if (_isAuthenticating) {
      debugPrint('⚠️ GATE: Auth blocked (Already authenticating)');
      return;
    }

    debugPrint('🔒 GATE: Starting authentication...');
    _isAuthenticating = true;
    _ignoreLifecycle = true; // 🔇 MUTE: Silence lifecycle listener
    notifyListeners();

    try {
      debugPrint('🔇 GATE: Lifecycle listener MUTED');
      final authenticated = await BiometricService.authenticate();
      
      if (authenticated) {
        debugPrint('✅ GATE: Auth Success! Unlocking UI immediately...');
        _isLocked = false;
        _pausedTime = null;
        
        // 🚀 INSTANT DISMISSAL: Update UI immediately to hide lock screen
        notifyListeners();
      } else {
        debugPrint('❌ GATE: Authentication failed or cancelled');
      }
    } catch (e) {
      debugPrint('⚠️ GATE: Authentication error: $e');
    } finally {
      _isAuthenticating = false;
      
      // 🔇 Safety period: Keep silencing for 500ms in background
      // Screen is already gone, user is using the app
      // But we protect against delayed Resume events
      debugPrint('🔇 GATE: Waiting 500ms safety period...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      _ignoreLifecycle = false; // 🔊 UNMUTE: Re-enable lifecycle listener
      debugPrint('🔊 GATE: Safety period ended. Listening enabled.');
      // No notifyListeners here - already called above
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
    debugPrint('⚙️ GATE: Config received. Enabled: ${config.lockEnabled}, Old: $wasLockEnabled');

    // Unlock if switching from ON to OFF
    if (!config.lockEnabled && wasLockEnabled) {
      debugPrint('🔓 GATE: Lock switched OFF → Unlocking app');
      _isLocked = false;
      _pausedTime = null;
      notifyListeners();
    }
    // Don't lock when enabling - wait for next pause/resume cycle
  }

  /// Set native FLAG_SECURE
  Future<void> _setSecureFlag(bool secure) async {
    // Skip on non-Android platforms
    if (!_isAndroid()) {
      return;
    }
    
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
  
  bool _isAndroid() {
    try {
      return Theme.of(WidgetsBinding.instance.rootElement!).platform == TargetPlatform.android;
    } catch (e) {
      return false;
    }
  }
}





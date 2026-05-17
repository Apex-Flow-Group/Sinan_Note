// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/services/security/security_gate.dart';
import 'package:apex_note/services/security/unified_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0;
  String _languageCode = 'system';
  String _fontFamily = 'system'; // 'system' | 'Cairo' | 'Tajawal'
  String _swipeRightAction = 'category';
  String _swipeLeftAction = 'share';
  bool _swipeEnabled = true;
  bool _doubleTapToEdit = true;
  List<String> _swipeCustomActions = ['delete', 'archive', 'share'];
  String _viewType = 'listCompact';
  bool _heroAnimationEnabled = false;
  bool _isAppLockEnabled = false;
  bool _customPinEnabled = false;
  bool _biometricLockEnabled = false;

  // Pull-to-refresh mode: 'full' | 'normal' | 'disabled'
  String _pullToRefreshMode = 'disabled';
  bool _hideNavOnScroll = false;
  bool _hideContentInBackground = false;
  bool _lockDelayEnabled = false;
  int _lockDelaySeconds = 30;
  bool _hasSeenLockedIntro = false;
  bool _isFirstLaunch = true;
  static const int _defaultBlueIndex = 8;
  static const int _defaultYellowIndex = 4;
  static const int _defaultPurpleIndex = 9;
  static const int _defaultGreenIndex = 5;
  static const int _defaultOrangeIndex = 3;

  final Map<String, int> _defaultColorIndices = {
    'simple': _defaultBlueIndex,
    'reminder': _defaultYellowIndex,
    'professional': _defaultPurpleIndex,
    'checklist': _defaultGreenIndex,
    'rich': _defaultOrangeIndex,
  };

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  String get languageCode => _languageCode;
  String get fontFamily => _fontFamily;
  String? get resolvedFontFamily =>
      _fontFamily == 'system' ? null : _fontFamily;
  String get swipeRightAction => _swipeRightAction;
  String get swipeLeftAction => _swipeLeftAction;
  bool get swipeEnabled => _swipeEnabled;
  bool get doubleTapToEdit => _doubleTapToEdit;
  List<String> get swipeCustomActions => _swipeCustomActions;
  String get viewType => _viewType;
  bool get heroAnimationEnabled => _heroAnimationEnabled;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get customPinEnabled => _customPinEnabled;
  bool get biometricLockEnabled => _biometricLockEnabled;
  String get pullToRefreshMode => _pullToRefreshMode;
  bool get hideNavOnScroll => _hideNavOnScroll;
  bool get hideContentInBackground => _hideContentInBackground;
  bool get lockDelayEnabled => _lockDelayEnabled;
  int get lockDelaySeconds => _lockDelaySeconds;
  bool get hasSeenLockedIntro => _hasSeenLockedIntro;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isSetupCompleted => !_isFirstLaunch;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isLoaded => _isInitialized;

  SettingsProvider() {
    Future.microtask(
      () => _loadSettings().catchError((e) {
        AppLogger.debug('Error loading settings: $e');
        _isInitialized = true;
        notifyListeners();
      }),
    );
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _loadSettings();
  }

  // ── SharedPreferences helper ──────────────────────────────────────────────

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else if (value == null) {
      await prefs.remove(key);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _savePref('themeMode', mode.index);
  }

  Future<void> setTextScaleFactor(double scale) async {
    _textScaleFactor = scale;
    notifyListeners();
    await _savePref('textScale', scale);
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    notifyListeners();
    await _savePref('fontFamily', family);
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    notifyListeners();
    await _savePref('language', code);
  }

  Future<void> setSwipeRightAction(String action) async {
    _swipeRightAction = action;
    notifyListeners();
    await _savePref('swipeRight', action);
  }

  Future<void> setSwipeLeftAction(String action) async {
    _swipeLeftAction = action;
    notifyListeners();
    await _savePref('swipeLeft', action);
  }

  Future<void> setSwipeCustomActions(List<String> actions) async {
    _swipeCustomActions = actions;
    notifyListeners();
    await _savePref('swipeCustomActions', actions);
  }

  Future<void> setSwipeEnabled(bool enabled) async {
    _swipeEnabled = enabled;
    notifyListeners();
    await _savePref('swipeEnabled', enabled);
  }

  Future<void> setDoubleTapToEdit(bool enabled) async {
    _doubleTapToEdit = enabled;
    notifyListeners();
    await _savePref('doubleTapToEdit', enabled);
  }

  Future<void> setHeroAnimationEnabled(bool enabled) async {
    _heroAnimationEnabled = enabled;
    notifyListeners();
    await _savePref('heroAnimationEnabled', enabled);
  }

  Future<void> setPullToRefreshMode(String mode) async {
    _pullToRefreshMode = mode;
    notifyListeners();
    await _savePref('pullToRefreshMode', mode);
  }

  Future<void> setHideNavOnScroll(bool enabled) async {
    _hideNavOnScroll = enabled;
    notifyListeners();
    await _savePref('hideNavOnScroll', enabled);
  }

  Future<void> setViewType(String key, String type) async {
    if (key == 'home') {
      _viewType = type;
    }
    notifyListeners();
    await _savePref('viewType_$key', type);
  }

  Future<String> getViewType(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('viewType_$key') ?? 'listCompact';
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    _isAppLockEnabled = enabled;
    notifyListeners();
    await _savePref('appLockEnabled', enabled);
    if (!enabled) UnifiedLockService().resetSession();
    _updateSecurityController();
  }

  Future<void> setBiometricLockEnabled(bool enabled) async {
    _biometricLockEnabled = enabled;
    notifyListeners();
    await _savePref('biometricLockEnabled', enabled);
  }

  Future<void> setCustomPinEnabled(bool enabled) async {
    _customPinEnabled = enabled;
    notifyListeners();
    await _savePref('customPinEnabled', enabled);
    if (!enabled) await UnifiedLockService().clearPin();
    _updateSecurityController();
  }

  Future<void> setHideContentInBackground(bool enabled) async {
    _hideContentInBackground = enabled;
    notifyListeners();
    await _savePref('hideContentInBackground', enabled);
    _updateSecurityController();
  }

  Future<void> setLockDelayEnabled(bool enabled) async {
    _lockDelayEnabled = enabled;
    notifyListeners();
    await _savePref('lockDelayEnabled', enabled);
    _updateSecurityController();
  }

  Future<void> setLockDelaySeconds(int seconds) async {
    _lockDelaySeconds = seconds;
    notifyListeners();
    await _savePref('lockDelaySeconds', seconds);
    _updateSecurityController();
  }

  Future<void> setLockedIntroSeen(bool value) async {
    _hasSeenLockedIntro = value;
    notifyListeners();
    await _savePref('seen_locked_intro', value);
  }

  Future<void> completeSetup() async {
    _isFirstLaunch = false;
    notifyListeners();
    await _savePref('first_launch', false);
  }

  Future<void> resetSetup() async {
    _isFirstLaunch = true;
    notifyListeners();
    await _savePref('first_launch', null);
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      int? themeIndex = prefs.getInt('themeMode');
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        _themeMode = ThemeMode.system;
      }
      _textScaleFactor = prefs.getDouble('textScale') ?? 1.0;
      _fontFamily = prefs.getString('fontFamily') ?? 'system';
      _languageCode = prefs.getString('language') ?? 'system';
      _swipeRightAction = prefs.getString('swipeRight') ?? 'category';
      _swipeLeftAction = prefs.getString('swipeLeft') ?? 'share';
      _swipeEnabled = prefs.getBool('swipeEnabled') ?? true;
      _doubleTapToEdit = prefs.getBool('doubleTapToEdit') ?? true;
      _swipeCustomActions = prefs.getStringList('swipeCustomActions') ??
          ['delete', 'archive', 'share'];
      _heroAnimationEnabled = prefs.getBool('heroAnimationEnabled') ?? false;
      _pullToRefreshMode = prefs.getString('pullToRefreshMode') ?? 'disabled';
      _hideNavOnScroll = prefs.getBool('hideNavOnScroll') ?? false;
      _viewType = prefs.getString('viewType') ?? 'listCompact';
      final homeViewType = prefs.getString('viewType_home');
      if (homeViewType != null) {
        _viewType = homeViewType;
      }
      _isAppLockEnabled = prefs.getBool('appLockEnabled') ?? false;
      _customPinEnabled = prefs.getBool('customPinEnabled') ?? false;
      _biometricLockEnabled = prefs.getBool('biometricLockEnabled') ?? false;
      _hideContentInBackground =
          prefs.getBool('hideContentInBackground') ?? false;
      _lockDelayEnabled = prefs.getBool('lockDelayEnabled') ?? false;
      _lockDelaySeconds = prefs.getInt('lockDelaySeconds') ?? 30;
      _hasSeenLockedIntro = prefs.getBool('seen_locked_intro') ?? false;
      _isFirstLaunch = prefs.getBool('first_launch') ?? true;
      _defaultColorIndices['simple'] =
          prefs.getInt('colorIndex_simple') ?? _defaultBlueIndex;
      _defaultColorIndices['reminder'] =
          prefs.getInt('colorIndex_reminder') ?? _defaultYellowIndex;
      _defaultColorIndices['professional'] =
          prefs.getInt('colorIndex_professional') ?? _defaultPurpleIndex;
      _defaultColorIndices['checklist'] =
          prefs.getInt('colorIndex_checklist') ?? _defaultGreenIndex;
      _defaultColorIndices['rich'] =
          prefs.getInt('colorIndex_rich') ?? _defaultOrangeIndex;

      _isInitialized = true;
      notifyListeners();

      // CRITICAL: Update SecurityController after loading settings
      _updateSecurityController();
    } catch (e) {
      AppLogger.debug('Error loading settings: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Locale? get locale {
    if (_languageCode == 'system') return null;
    return Locale(_languageCode);
  }

  int getDefaultColorIndex(String mode) {
    return _defaultColorIndices[mode] ?? _defaultBlueIndex;
  }

  Future<void> setDefaultColorIndex(String mode, int index) async {
    _defaultColorIndices[mode] = index;
    notifyListeners();
    await _savePref('colorIndex_$mode', index);
  }

  void _updateSecurityController() {
    final effectiveDelaySeconds = _lockDelayEnabled ? _lockDelaySeconds : 0;

    final newConfig = SecurityConfig(
      lockEnabled: _isAppLockEnabled,
      lockDelaySeconds: effectiveDelaySeconds,
      privacyBlurEnabled: _hideContentInBackground,
      biometricEnabled: _biometricLockEnabled,
    );

    // Skip update if config hasn't changed
    final controller = SecurityController();
    if (controller.config.lockEnabled == newConfig.lockEnabled &&
        controller.config.lockDelaySeconds == newConfig.lockDelaySeconds &&
        controller.config.privacyBlurEnabled == newConfig.privacyBlurEnabled &&
        controller.config.biometricEnabled == newConfig.biometricEnabled) {
      return; // No change, skip update
    }

    AppLogger.debug(
      '🔒 Updating Security Config: Lock=$_isAppLockEnabled, Delay=${effectiveDelaySeconds}s, Privacy=$_hideContentInBackground',
    );
    controller.updateConfig(newConfig);
  }
}

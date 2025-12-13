// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {

  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0;
  String _languageCode = 'system';
  String _swipeRightAction = 'delete';
  String _swipeLeftAction = 'archive';
  bool _swipeEnabled = true;
  bool _cardMotionEnabled = false;
  String _viewType = 'listCompact';
  bool _isAppLockEnabled = false;
  bool _hideContentInBackground = true;
  bool _lockDelayEnabled = false;
  int _lockDelaySeconds = 30;
  bool _hasSeenLockedIntro = false;
  bool _isFirstLaunch = true;
  final Map<String, int> _defaultColorIndices = {
    'simple': 8,      // Blue
    'reminder': 4,    // Yellow
    'professional': 9, // Purple
  };

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  String get languageCode => _languageCode;
  String get swipeRightAction => _swipeRightAction;
  String get swipeLeftAction => _swipeLeftAction;
  bool get swipeEnabled => _swipeEnabled;
  bool get cardMotionEnabled => _cardMotionEnabled;
  String get viewType => _viewType;
  bool get isAppLockEnabled => _isAppLockEnabled;
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
    _loadSettings();
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _loadSettings();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setTextScaleFactor(double scale) async {
    _textScaleFactor = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', scale);
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
  }

  Future<void> setSwipeRightAction(String action) async {
    _swipeRightAction = action;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('swipeRight', action);
  }

  Future<void> setSwipeLeftAction(String action) async {
    _swipeLeftAction = action;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('swipeLeft', action);
  }

  Future<void> setSwipeEnabled(bool enabled) async {
    _swipeEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('swipeEnabled', enabled);
  }

  Future<void> setCardMotionEnabled(bool enabled) async {
    _cardMotionEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cardMotionEnabled', enabled);
  }

  Future<void> setViewType(String type) async {
    _viewType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('viewType', type);
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    _isAppLockEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLockEnabled', enabled);
    await _updateNativeSecureFlag();
  }

  Future<void> setHideContentInBackground(bool enabled) async {
    _hideContentInBackground = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideContentInBackground', enabled);
    await _updateNativeSecureFlag();
  }

  Future<void> _updateNativeSecureFlag() async {
    try {
      const platform = MethodChannel('com.apexflow.app.sinan/security');
      await platform.invokeMethod('updateSecureFlag', {
        'enabled': _hideContentInBackground || _isAppLockEnabled,
      });
    } catch (e) {
      // Platform channel not available (iOS or error)
    }
  }

  Future<void> setLockDelayEnabled(bool enabled) async {
    _lockDelayEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lockDelayEnabled', enabled);
  }

  Future<void> setLockDelaySeconds(int seconds) async {
    _lockDelaySeconds = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lockDelaySeconds', seconds);
  }

  Future<void> setLockedIntroSeen(bool value) async {
    _hasSeenLockedIntro = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_locked_intro', value);
  }

  Future<void> completeSetup() async {
    _isFirstLaunch = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
  }

  Future<void> resetSetup() async {
    _isFirstLaunch = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('first_launch');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int? themeIndex = prefs.getInt('themeMode');
    _themeMode =
        themeIndex != null ? ThemeMode.values[themeIndex] : ThemeMode.system;
    _textScaleFactor = prefs.getDouble('textScale') ?? 1.0;
    _languageCode = prefs.getString('language') ?? 'system';
    _swipeRightAction = prefs.getString('swipeRight') ?? 'delete';
    _swipeLeftAction = prefs.getString('swipeLeft') ?? 'archive';
    _swipeEnabled = prefs.getBool('swipeEnabled') ?? true;
    _cardMotionEnabled = prefs.getBool('cardMotionEnabled') ?? false;
    _viewType = prefs.getString('viewType') ?? 'listCompact';
    _isAppLockEnabled = prefs.getBool('appLockEnabled') ?? false;
    _hideContentInBackground = prefs.getBool('hideContentInBackground') ?? true;
    _lockDelayEnabled = prefs.getBool('lockDelayEnabled') ?? false;
    _lockDelaySeconds = prefs.getInt('lockDelaySeconds') ?? 30;
    _hasSeenLockedIntro = prefs.getBool('seen_locked_intro') ?? false;
    _isFirstLaunch = prefs.getBool('first_launch') ?? true;
    _defaultColorIndices['simple'] = prefs.getInt('colorIndex_simple') ?? 8;
    _defaultColorIndices['reminder'] = prefs.getInt('colorIndex_reminder') ?? 4;
    _defaultColorIndices['professional'] = prefs.getInt('colorIndex_professional') ?? 9;
    _isInitialized = true;
    notifyListeners();
  }

  Locale? get locale {
    if (_languageCode == 'system') return null;
    return Locale(_languageCode);
  }

  int getDefaultColorIndex(String mode) {
    return _defaultColorIndices[mode] ?? 8;
  }

  Future<void> setDefaultColorIndex(String mode, int index) async {
    _defaultColorIndices[mode] = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorIndex_$mode', index);
  }
}

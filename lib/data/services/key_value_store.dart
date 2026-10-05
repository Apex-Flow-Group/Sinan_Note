// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:shared_preferences/shared_preferences.dart';

/// قيم صغيرة دائمة (حالة المزامنة مثلاً). تُحقن فيُختبر مستخدمها بلا
/// SharedPreferences العامة.
abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
}

class PreferencesStore implements KeyValueStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async => (await _prefs).getString(key);
  @override
  Future<void> setString(String key, String value) async =>
      (await _prefs).setString(key, value);
  @override
  Future<int?> getInt(String key) async => (await _prefs).getInt(key);
  @override
  Future<void> setInt(String key, int value) async =>
      (await _prefs).setInt(key, value);
  @override
  Future<bool?> getBool(String key) async => (await _prefs).getBool(key);
  @override
  Future<void> setBool(String key, bool value) async =>
      (await _prefs).setBool(key, value);
}

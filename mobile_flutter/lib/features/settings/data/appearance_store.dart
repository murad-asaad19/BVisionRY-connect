import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed persistence for the app's [ThemeMode] choice
/// (System / Light / Dark).
///
/// Single source of truth for the user's appearance preference across cold
/// starts. Mirrors [LanguageService]: [load] resolves the persisted value
/// (defaulting to [ThemeMode.system] when nothing is stored or the stored
/// value is no longer recognised) and [save] persists a new choice.
///
/// The chosen mode is stored as its [ThemeMode.name] (`system` / `light` /
/// `dark`) so the on-disk value stays human-readable and stable across
/// enum-index reordering.
class AppearanceStore {
  /// SharedPreferences key holding the persisted [ThemeMode] name.
  static const String _key = 'connect.theme_mode';

  /// Reads the persisted theme mode, defaulting to [ThemeMode.system] when
  /// nothing is stored or the stored name is unrecognised.
  Future<ThemeMode> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString(_key);
    return _fromName(name);
  }

  /// Persists [mode] as its enum name.
  Future<void> save(ThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  static ThemeMode _fromName(String? name) {
    for (final ThemeMode m in ThemeMode.values) {
      if (m.name == name) return m;
    }
    return ThemeMode.system;
  }
}

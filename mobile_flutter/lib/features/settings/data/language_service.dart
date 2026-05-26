import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed locale persistence.
///
/// Single source of truth for the user's preferred app locale across
/// cold starts. The locale flips synchronously via [save], so the calling
/// screen can update `localeProvider` immediately after the future resolves
/// and the next frame re-renders in the new language.
///
/// Supported codes are pinned in [supported]. Adding a new language means:
///   1. Drop a `lib/core/i18n/locales/<code>.json` bundle.
///   2. Add the code to [supported].
///   3. Add `settings.language.<code>` translations.
class LanguageService {
  /// SharedPreferences key holding the persisted ISO 639-1 code.
  static const String _key = 'connect.locale';

  /// Locale codes the app ships translations for. Anything outside this set
  /// is rejected by [save] and treated as `en` on [load].
  static const List<String> supported = <String>['en', 'es'];

  /// Reads the persisted locale, defaulting to `en` when nothing is stored
  /// or when the stored code is no longer in [supported] (e.g. after a
  /// locale was removed in a subsequent release).
  Future<Locale> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_key);
    if (code == null || !supported.contains(code)) {
      return const Locale('en');
    }
    return Locale(code);
  }

  /// Persists [locale]. Throws [ArgumentError] when the language is not in
  /// [supported] so the caller can show a developer-friendly error rather
  /// than the user ending up on the fallback bundle silently.
  Future<void> save(Locale locale) async {
    if (!supported.contains(locale.languageCode)) {
      throw ArgumentError('unsupported locale: ${locale.languageCode}');
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

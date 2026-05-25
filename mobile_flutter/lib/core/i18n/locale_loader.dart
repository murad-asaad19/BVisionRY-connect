import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads a locale JSON bundle from `lib/core/i18n/locales/<code>.json` and
/// resolves keys with dotted paths, `{{var}}` interpolation, and `_one` /
/// `_other` plural selection.
///
/// Behaviour matches `mobile/src/lib/i18n/index.ts` (the RN port) so JSON
/// files can be shared verbatim.
class LocaleLoader {
  Map<String, dynamic> _data = const <String, dynamic>{};
  String _code = '';

  /// Locale code currently loaded (empty until [load] resolves).
  String get code => _code;

  /// Loads `lib/core/i18n/locales/[code].json` into memory.
  Future<void> load(String code) async {
    final String raw =
        await rootBundle.loadString('lib/core/i18n/locales/$code.json');
    _data = jsonDecode(raw) as Map<String, dynamic>;
    _code = code;
  }

  /// Resolves [key] against the loaded bundle.
  ///
  /// When `vars['count']` is a number, the lookup first tries `${key}_one`
  /// (for `count == 1`) or `${key}_other` (otherwise) and falls back to the
  /// bare key. Returns [key] itself when no entry exists, so callers can
  /// detect missing translations.
  String t(String key, {Map<String, Object>? vars}) {
    final Object? count = vars?['count'];
    final String? pluralSuffix =
        count is num ? (count == 1 ? '_one' : '_other') : null;
    String? value;
    if (pluralSuffix != null) {
      value = _lookup('$key$pluralSuffix');
    }
    value ??= _lookup(key);
    if (value == null) return key;
    return _interpolate(value, vars);
  }

  String? _lookup(String key) {
    final List<String> parts = key.split('.');
    Object? cursor = _data;
    for (final String p in parts) {
      if (cursor is Map<String, dynamic> && cursor.containsKey(p)) {
        cursor = cursor[p];
      } else {
        return null;
      }
    }
    return cursor is String ? cursor : null;
  }

  String _interpolate(String template, Map<String, Object>? vars) {
    if (vars == null || vars.isEmpty) return template;
    String out = template;
    vars.forEach((String k, Object v) {
      out = out.replaceAll('{{$k}}', v.toString());
    });
    return out;
  }
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Phase 15 — locale-key-tree parity report.
///
/// Walks each locale JSON, flattens dotted keys, then computes the
/// symmetric difference. Used by tests to guarantee `en.json` and
/// `es.json` stay in lock-step.
class ParityReport {
  ParityReport({
    required this.totalKeys,
    required this.missingInEn,
    required this.missingInEs,
  });

  final int totalKeys;
  final List<String> missingInEn;
  final List<String> missingInEs;
}

abstract final class LocaleParity {
  static Future<ParityReport> compare(List<String> codes) async {
    assert(codes.length == 2);
    final enKeys = await flatten(codes[0]);
    final esKeys = await flatten(codes[1]);
    final missingInEs = enKeys.difference(esKeys).toList()..sort();
    final missingInEn = esKeys.difference(enKeys).toList()..sort();
    return ParityReport(
      totalKeys: enKeys.length,
      missingInEn: missingInEn,
      missingInEs: missingInEs,
    );
  }

  static Future<Set<String>> flatten(String code) async {
    final raw = await rootBundle.loadString('lib/core/i18n/locales/$code.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String>{};
    void walk(Map<String, dynamic> map, String prefix) {
      map.forEach((k, v) {
        final key = prefix.isEmpty ? k : '$prefix.$k';
        if (v is Map<String, dynamic>) {
          walk(v, key);
        } else {
          out.add(key);
        }
      });
    }

    walk(data, '');
    return out;
  }
}

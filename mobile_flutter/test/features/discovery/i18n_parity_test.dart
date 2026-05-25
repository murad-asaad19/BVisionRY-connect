import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'en and es share the same key set for discovery + home additions',
    () {
      final en = jsonDecode(
        File('lib/core/i18n/locales/en.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final es = jsonDecode(
        File('lib/core/i18n/locales/es.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final k in const <String>[
        'discovery.reason.complementaryGoals',
        'discovery.reason.sharedRole',
        'discovery.reason.sameCity',
        'discovery.reason.newOnConnect',
        'discovery.reason.dailyPick',
        'discovery.filtersApply',
        'discovery.filtersReset',
        'discovery.filtersRoles',
        'discovery.filtersGoals',
        'discovery.filtersCountry',
        'discovery.openSearch',
        'discovery.searchEmptyTitle',
        'discovery.searchEmptyBody',
        'home.picksHeader_one',
        'home.picksHeader_other',
        'home.matchesEmptyTitle',
        'home.matchesEmptyBody',
        'common.tabs.home',
        'common.tabs.inbox',
        'common.tabs.network',
        'common.tabs.opportunities',
        'common.tabs.chats',
      ]) {
        expect(_resolve(en, k), isA<String>(), reason: 'en missing $k');
        expect(_resolve(es, k), isA<String>(), reason: 'es missing $k');
      }
    },
  );
}

Object? _resolve(Map<String, dynamic> root, String key) {
  Object? cur = root;
  for (final p in key.split('.')) {
    if (cur is Map<String, dynamic> && cur.containsKey(p)) {
      cur = cur[p];
    } else {
      return null;
    }
  }
  return cur;
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('en.json contains all office-hours phase-9 keys', () {
    final en = jsonDecode(
      File('lib/core/i18n/locales/en.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final oh = en['officeHours'] as Map<String, dynamic>;
    expect(
      (oh['book'] as Map<String, dynamic>).keys,
      containsAll(<String>[
        'duration',
        'errorTooSoon',
        'errorBlocked',
        'errorWeeklyCap',
        'errorHostSelf',
        'errorOhDisabled',
        'errorBadMeetingUrl',
        'errorTopicInvalid',
        'errorSlotUnavailable',
      ]),
    );
    expect(
      (oh['bookings'] as Map<String, dynamic>).keys,
      contains('errorNotBooked'),
    );
    expect(
      (oh['settings'] as Map<String, dynamic>).keys,
      containsAll(<String>[
        'windowsEmpty',
        'editWindow',
        'startTime',
        'endTime',
        'invalidSlotDuration',
        'invalidMaxBookings',
        'invalidBuffer',
        'windowInvalidWeekday',
        'windowInvalidStart',
        'windowInvalidEnd',
        'windowInvalidTimezone',
        'meetingLinkHttpsRequired',
      ]),
    );
  });

  test('es.json key-set equals en.json key-set under officeHours.*', () {
    final en = jsonDecode(
      File('lib/core/i18n/locales/en.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final es = jsonDecode(
      File('lib/core/i18n/locales/es.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    Iterable<String> leafKeys(Map<String, dynamic> m, String prefix) sync* {
      for (final e in m.entries) {
        final v = e.value;
        if (v is Map<String, dynamic>) {
          yield* leafKeys(v, '$prefix${e.key}.');
        } else {
          yield '$prefix${e.key}';
        }
      }
    }

    final enKeys =
        leafKeys(en['officeHours'] as Map<String, dynamic>, '').toSet();
    final esKeys =
        leafKeys(es['officeHours'] as Map<String, dynamic>, '').toSet();
    expect(esKeys, equals(enKeys));
  });
}

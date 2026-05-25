import 'package:connect_mobile/features/discovery/domain/match_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses every documented server string', () {
    expect(
      MatchReason.fromServer('Complementary goals'),
      MatchReason.complementaryGoals,
    );
    expect(MatchReason.fromServer('Shared role'), MatchReason.sharedRole);
    expect(MatchReason.fromServer('Same city'), MatchReason.sameCity);
    expect(MatchReason.fromServer('New on Connect'), MatchReason.newOnConnect);
    expect(MatchReason.fromServer('Daily pick'), MatchReason.dailyPick);
  });

  test('unknown string falls back to dailyPick (never breaks UI)', () {
    expect(MatchReason.fromServer('something exotic'), MatchReason.dailyPick);
  });

  test('every reason exposes an i18n key under discovery.reason.*', () {
    for (final r in MatchReason.values) {
      expect(r.i18nKey, startsWith('discovery.reason.'));
    }
  });
}

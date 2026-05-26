import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocaleLoader loads en and resolves nested keys', () async {
    final loader = LocaleLoader();
    await loader.load('en');
    expect(loader.t('common.cancel'), isNotEmpty);
    expect(loader.t('common.cancel'), isNot(equals('common.cancel')));
  });

  test('LocaleLoader interpolates {{var}}', () async {
    final loader = LocaleLoader();
    await loader.load('en');
    // Use a known key with a variable from the locale JSON (e.g. onboarding.stepLabel)
    final out = loader.t(
      'onboarding.stepLabel',
      vars: <String, Object>{'current': 2, 'total': 4, 'stepName': 'Identity'},
    );
    expect(out, contains('2'));
    expect(out, contains('Identity'));
  });

  test('LocaleLoader picks _one / _other plural by count', () async {
    final loader = LocaleLoader();
    await loader.load('en');
    // Use an existing _one/_other pair; profile.signals.mutual_one / _other
    final one = loader.t(
      'profile.signals.mutual',
      vars: <String, Object>{'count': 1},
    );
    final other = loader.t(
      'profile.signals.mutual',
      vars: <String, Object>{'count': 5},
    );
    expect(one, isNot(equals(other)));
  });

  test('LocaleLoader returns missing key path when key absent', () async {
    final loader = LocaleLoader();
    await loader.load('en');
    expect(loader.t('not.a.real.key'), equals('not.a.real.key'));
  });

  test('all meetings.* keys resolve in en + es (no fallbacks)', () async {
    for (final code in const ['en', 'es']) {
      final loader = LocaleLoader();
      await loader.load(code);
      for (final key in const [
        'meetings.title',
        'meetings.statusProposed',
        'meetings.statusConfirmed',
        'meetings.statusDeclined',
        'meetings.statusCancelled',
        'meetings.confirm',
        'meetings.decline',
        'meetings.cancelProposal',
        'meetings.addToCalendar',
        'meetings.errors.actionFailed',
        'meetings.propose.title',
        'meetings.propose.subtitle',
        'meetings.propose.slot1Label',
        'meetings.propose.slot2Label',
        'meetings.propose.slot3Label',
        'meetings.propose.durationLabel',
        'meetings.propose.urlLabel',
        'meetings.propose.urlPlaceholder',
        'meetings.propose.cancel',
        'meetings.propose.send',
        'meetings.propose.errors.slotsRange',
        'meetings.propose.errors.duration',
        'meetings.propose.errors.url',
        'meetings.propose.errors.submitFailed',
        'meetings.confirmSheet.title',
        'meetings.confirmSheet.subtitle',
        'meetings.prompt.title',
        'meetings.prompt.subtitle',
        'meetings.review.title',
        'meetings.review.subtitle',
        'meetings.review.useful',
        'meetings.review.notUseful',
        'meetings.review.noShow',
        'meetings.review.skip',
        'meetings.review.submitFailed',
        'meetings.review.submitted',
        'meetings.playbook.title',
        'meetings.playbook.generating',
        'meetings.playbook.regenerate',
        'meetings.playbook.regenerateRateLimited',
        'meetings.playbook.generate',
        'meetings.playbook.retry',
        'meetings.playbook.errorBanner',
        'meetings.playbook.justNow',
        'meetings.playbook.minutesShort',
        'meetings.playbook.hoursShort',
        'meetings.playbook.daysShort',
        'meetings.playbook.section.sharedInterests',
        'meetings.playbook.section.conversationStarters',
        'meetings.playbook.section.do',
        'meetings.playbook.section.dont',
      ]) {
        expect(loader.t(key), isNot(equals(key)),
            reason: 'missing $key in $code',);
      }
      // Keys with vars need separate handling — assert their interpolated
      // form differs from the raw key.
      expect(
        loader.t('meetings.durationLabel', vars: {'minutes': 30}),
        isNot(equals('meetings.durationLabel')),
        reason: 'missing meetings.durationLabel in $code',
      );
      expect(
        loader.t(
          'meetings.propose.durationOption',
          vars: {'minutes': 30},
        ),
        isNot(equals('meetings.propose.durationOption')),
        reason: 'missing meetings.propose.durationOption in $code',
      );
      expect(
        loader.t('meetings.propose.inputTimeZoneHint', vars: {'tz': 'UTC'}),
        isNot(equals('meetings.propose.inputTimeZoneHint')),
        reason: 'missing meetings.propose.inputTimeZoneHint in $code',
      );
      expect(
        loader.t('meetings.playbook.generatedAt', vars: {'ago': 'just now'}),
        isNot(equals('meetings.playbook.generatedAt')),
        reason: 'missing meetings.playbook.generatedAt in $code',
      );
    }
  });
}

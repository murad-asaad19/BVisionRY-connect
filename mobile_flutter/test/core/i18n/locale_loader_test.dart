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
}

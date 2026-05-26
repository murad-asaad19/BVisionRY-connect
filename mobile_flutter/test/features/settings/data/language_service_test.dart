import 'package:connect_mobile/features/settings/data/language_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('LanguageService.load returns en when nothing persisted', () async {
    final LanguageService svc = LanguageService();
    expect((await svc.load()).languageCode, 'en');
  });

  test('LanguageService.save persists locale and load reads it back', () async {
    final LanguageService svc = LanguageService();
    await svc.save(const Locale('es'));
    expect((await svc.load()).languageCode, 'es');
  });

  test('LanguageService.save rejects unsupported locales', () async {
    final LanguageService svc = LanguageService();
    expect(() => svc.save(const Locale('fr')), throwsArgumentError);
  });

  test('LanguageService.load coerces stored unsupported code back to en',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'connect.locale': 'fr',
    });
    final LanguageService svc = LanguageService();
    expect((await svc.load()).languageCode, 'en');
  });
}

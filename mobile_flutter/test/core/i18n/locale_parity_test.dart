import 'package:connect_mobile/core/i18n/locale_parity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('en.json and es.json have identical key trees', () async {
    final report = await LocaleParity.compare(['en', 'es']);
    expect(
      report.missingInEs,
      isEmpty,
      reason: 'keys present in en but missing in es: ${report.missingInEs}',
    );
    expect(
      report.missingInEn,
      isEmpty,
      reason: 'keys present in es but missing in en: ${report.missingInEn}',
    );
    expect(report.totalKeys, greaterThan(0));
  });
}

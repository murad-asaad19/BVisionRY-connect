import 'package:connect_mobile/features/privacy/domain/report_target_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportTargetType', () {
    test('wire returns the postgres enum literal', () {
      expect(ReportTargetType.profile.wire, 'profile');
      expect(ReportTargetType.message.wire, 'message');
      expect(ReportTargetType.intro.wire, 'intro');
    });

    test('values length == 3 (matches spec §2.12 enum)', () {
      expect(ReportTargetType.values.length, 3);
    });

    test('stable enum order', () {
      expect(ReportTargetType.values, <ReportTargetType>[
        ReportTargetType.profile,
        ReportTargetType.message,
        ReportTargetType.intro,
      ]);
    });
  });
}

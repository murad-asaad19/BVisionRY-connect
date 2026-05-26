import 'package:connect_mobile/features/privacy/domain/report_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportReason', () {
    test('values length == 5 with stable spec order', () {
      expect(ReportReason.values, <ReportReason>[
        ReportReason.spam,
        ReportReason.harassment,
        ReportReason.impersonation,
        ReportReason.inappropriate,
        ReportReason.other,
      ]);
    });

    test('wire is the postgres enum literal for every value', () {
      for (final ReportReason r in ReportReason.values) {
        expect(r.wire, r.name);
      }
    });

    test('i18nKey points at privacy.reportModal.reasons.<name>', () {
      expect(ReportReason.spam.i18nKey, 'privacy.reportModal.reasons.spam');
      expect(
        ReportReason.harassment.i18nKey,
        'privacy.reportModal.reasons.harassment',
      );
      expect(
        ReportReason.impersonation.i18nKey,
        'privacy.reportModal.reasons.impersonation',
      );
      expect(
        ReportReason.inappropriate.i18nKey,
        'privacy.reportModal.reasons.inappropriate',
      );
      expect(ReportReason.other.i18nKey, 'privacy.reportModal.reasons.other');
    });
  });
}

import 'package:connect_mobile/features/privacy/data/privacy_service.dart';
import 'package:connect_mobile/features/privacy/domain/report_reason.dart';
import 'package:connect_mobile/features/privacy/domain/report_target_type.dart';
import 'package:connect_mobile/features/privacy/presentation/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements PrivacyService {}

/// Localised label for each ReportReason — matches en.json.
String _label(ReportReason r) => switch (r) {
      ReportReason.spam => 'Spam',
      ReportReason.harassment => 'Harassment',
      ReportReason.impersonation => 'Impersonation',
      ReportReason.inappropriate => 'Inappropriate content',
      ReportReason.other => 'Other',
    };

Future<void> _pumpSheetOpener(
  WidgetTester tester, {
  required _FakeService service,
  required ReportTargetType targetType,
  required String targetId,
  String? quotedMessageId,
  String? quotedBodyPreview,
}) async {
  await tester.pumpWidget(
    await wrapWithTheme(
      child: Builder(
        builder: (BuildContext ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showReportSheet(
                ctx,
                targetType: targetType,
                targetId: targetId,
                quotedMessageId: quotedMessageId,
                quotedBodyPreview: quotedBodyPreview,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      overrides: <Override>[
        privacyServiceProvider.overrideWithValue(service),
      ],
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(ReportTargetType.profile);
    registerFallbackValue(ReportReason.spam);
  });

  // ---- Reason buttons fire submit with the right enum (15 cases — 5
  // reasons × 3 target types). One representative pair per target keeps the
  // suite fast; we already cover all 5 reasons against `profile`.
  // ---------------------------------------------------------------------
  for (final ReportReason reason in ReportReason.values) {
    testWidgets('profile target: ${reason.wire} reason → submit forwards enum',
        (tester) async {
      final _FakeService svc = _FakeService();
      when(
        () => svc.reportTarget(
          targetType: any(named: 'targetType'),
          targetId: any(named: 'targetId'),
          reason: any(named: 'reason'),
          note: any(named: 'note'),
          quotedMessageId: any(named: 'quotedMessageId'),
        ),
      ).thenAnswer((_) async {});

      await _pumpSheetOpener(
        tester,
        service: svc,
        targetType: ReportTargetType.profile,
        targetId: 't1',
      );

      await tester.tap(find.text(_label(reason)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      verify(
        () => svc.reportTarget(
          targetType: ReportTargetType.profile,
          targetId: 't1',
          reason: reason,
          note: null,
          quotedMessageId: null,
        ),
      ).called(1);
    });
  }

  testWidgets('intro target forwards ReportTargetType.intro', (tester) async {
    final _FakeService svc = _FakeService();
    when(
      () => svc.reportTarget(
        targetType: any(named: 'targetType'),
        targetId: any(named: 'targetId'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        quotedMessageId: any(named: 'quotedMessageId'),
      ),
    ).thenAnswer((_) async {});
    await _pumpSheetOpener(
      tester,
      service: svc,
      targetType: ReportTargetType.intro,
      targetId: 'intro-1',
    );
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    verify(
      () => svc.reportTarget(
        targetType: ReportTargetType.intro,
        targetId: 'intro-1',
        reason: ReportReason.other,
        note: null,
        quotedMessageId: null,
      ),
    ).called(1);
  });

  // ---- Validation: pickReason guard ----------------------------------
  testWidgets(
      'Submit without a reason shows pickReasonBody error + does NOT call service',
      (tester) async {
    final _FakeService svc = _FakeService();
    await _pumpSheetOpener(
      tester,
      service: svc,
      targetType: ReportTargetType.profile,
      targetId: 't1',
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Select what to report'), findsOneWidget);
    verifyNever(
      () => svc.reportTarget(
        targetType: any(named: 'targetType'),
        targetId: any(named: 'targetId'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        quotedMessageId: any(named: 'quotedMessageId'),
      ),
    );
  });

  testWidgets(
      'picking a reason after a failed pickReason guard clears the error',
      (tester) async {
    final _FakeService svc = _FakeService();
    await _pumpSheetOpener(
      tester,
      service: svc,
      targetType: ReportTargetType.profile,
      targetId: 't1',
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Select what to report'), findsOneWidget);

    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Select what to report'), findsNothing);
  });

  // ---- Note cap enforced at the field level (≤1000 chars) ------------
  testWidgets('note input enforces 1000-char cap', (tester) async {
    final _FakeService svc = _FakeService();
    when(
      () => svc.reportTarget(
        targetType: any(named: 'targetType'),
        targetId: any(named: 'targetId'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        quotedMessageId: any(named: 'quotedMessageId'),
      ),
    ).thenAnswer((_) async {});
    await _pumpSheetOpener(
      tester,
      service: svc,
      targetType: ReportTargetType.profile,
      targetId: 'p',
    );

    final String tooLong = 'x' * 1500;
    await tester.enterText(find.byType(TextField), tooLong);
    await tester.pump();
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, lessThanOrEqualTo(1000));
  });

  // ---- Quoted-message preview renders only when a preview is supplied
  testWidgets(
      'quoted preview renders when quotedBodyPreview is provided + submit forwards quotedMessageId',
      (tester) async {
    final _FakeService svc = _FakeService();
    when(
      () => svc.reportTarget(
        targetType: any(named: 'targetType'),
        targetId: any(named: 'targetId'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        quotedMessageId: any(named: 'quotedMessageId'),
      ),
    ).thenAnswer((_) async {});

    await _pumpSheetOpener(
      tester,
      service: svc,
      targetType: ReportTargetType.message,
      targetId: 'msg-7',
      quotedMessageId: 'msg-7',
      quotedBodyPreview: 'You should DM me about pricing',
    );

    expect(find.text('Quoted message'), findsOneWidget);
    expect(find.text('You should DM me about pricing'), findsOneWidget);

    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    verify(
      () => svc.reportTarget(
        targetType: ReportTargetType.message,
        targetId: 'msg-7',
        reason: ReportReason.spam,
        note: null,
        quotedMessageId: 'msg-7',
      ),
    ).called(1);
  });

  testWidgets('no quoted preview rendered when quotedBodyPreview is null',
      (tester) async {
    final _FakeService svc = _FakeService();
    await _pumpSheetOpener(
      tester,
      service: svc,
      targetType: ReportTargetType.profile,
      targetId: 't1',
    );
    expect(find.text('Quoted message'), findsNothing);
  });

  // ---- Note text is forwarded when non-empty -------------------------
  testWidgets('non-empty note is forwarded to service.reportTarget',
      (tester) async {
    final _FakeService svc = _FakeService();
    when(
      () => svc.reportTarget(
        targetType: any(named: 'targetType'),
        targetId: any(named: 'targetId'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        quotedMessageId: any(named: 'quotedMessageId'),
      ),
    ).thenAnswer((_) async {});
    await _pumpSheetOpener(
      tester,
      service: svc,
      targetType: ReportTargetType.profile,
      targetId: 'p',
    );
    await tester.tap(find.text('Harassment'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'They DMed insults.');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    verify(
      () => svc.reportTarget(
        targetType: ReportTargetType.profile,
        targetId: 'p',
        reason: ReportReason.harassment,
        note: 'They DMed insults.',
        quotedMessageId: null,
      ),
    ).called(1);
  });
}

import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/verification/data/verification_service.dart';
import 'package:connect_mobile/features/verification/domain/verification_request.dart';
import 'package:connect_mobile/features/verification/presentation/verification_screen.dart';
import 'package:connect_mobile/features/verification/providers/my_verifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/pump.dart';

class _NoRowRunner implements ProfileQueryRunner {
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => null;
}

class _RecordingVerificationService extends VerificationService {
  _RecordingVerificationService() : super(_StubGateway());
  bool clearedGithub = false;
  VerificationKind? submittedKind;
  Map<String, dynamic>? submittedPayload;

  @override
  Future<void> clearGithubVerification() async {
    clearedGithub = true;
  }

  @override
  Future<void> submitVerification(
    VerificationKind kind, {
    Map<String, dynamic>? payload,
  }) async {
    submittedKind = kind;
    submittedPayload = payload;
  }
}

class _StubGateway implements VerificationGateway {
  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) async =>
      null;
}

Profile _profileWith({String? github}) => Profile.empty('u-1').copyWith(
      onboarded: true,
      verifiedGithubUsername: github,
    );

Future<Widget> _renderVerification({
  required Profile profile,
  VerificationService? svc,
  Map<VerificationKind, VerificationRequest> submissions =
      const <VerificationKind, VerificationRequest>{},
}) async {
  final FakeAuthGateway auth = FakeAuthGateway();
  auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u-1'));
  return wrapWithTheme(
    child: const VerificationScreen(),
    overrides: <Override>[
      authGatewayProvider.overrideWithValue(auth),
      profileRepositoryProvider
          .overrideWithValue(ProfileRepository(_NoRowRunner())),
      profileProvider
          .overrideWith((Ref<AsyncValue<Profile?>> _) async => profile),
      // Stub the caller's submissions so the Founder/Investor proof rows
      // never reach for a live Supabase client.
      myVerificationsProvider.overrideWith(
        (Ref<AsyncValue<Map<VerificationKind, VerificationRequest>>> _) async =>
            submissions,
      ),
      if (svc != null) verificationServiceProvider.overrideWithValue(svc),
    ],
  );
}

VerificationRequest _req(
  VerificationKind kind,
  VerificationStatus status, {
  String? note,
}) =>
    VerificationRequest(
      id: 'v-${kind.wire}',
      kind: kind,
      status: status,
      createdAt: DateTime.utc(2026),
      note: note,
    );

void main() {
  group('VerificationScreen', () {
    testWidgets('renders GitHub row + actionable rows for other proof types', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await _renderVerification(profile: _profileWith()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('verification.row.github')), findsOneWidget);
      expect(find.byKey(const Key('verification.row.domain')), findsOneWidget);
      expect(
        find.byKey(
          const Key('verification.row.team_page'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('verification.row.crunchbase'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('verification.row.portfolio'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      // Un-submitted proofs surface a "Request verification" button.
      expect(
        find.byKey(
          const Key('verification.row.domain.request'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the verified github handle when verified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await _renderVerification(profile: _profileWith(github: 'octocat')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('octocat'), findsOneWidget);
      expect(
        find.byKey(const Key('verification.github.disconnect')),
        findsOneWidget,
      );
    });

    testWidgets('Disconnect calls clearGithubVerification', (
      WidgetTester tester,
    ) async {
      final _RecordingVerificationService svc = _RecordingVerificationService();
      await tester.pumpWidget(
        await _renderVerification(
          profile: _profileWith(github: 'octocat'),
          svc: svc,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('verification.github.disconnect')));
      await tester.pumpAndSettle();
      expect(svc.clearedGithub, isTrue);
    });

    testWidgets('pending submission renders the Pending review pill', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await _renderVerification(
          profile: _profileWith(),
          submissions: <VerificationKind, VerificationRequest>{
            VerificationKind.investorCrunchbase: _req(
              VerificationKind.investorCrunchbase,
              VerificationStatus.pending,
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const Key('verification.row.crunchbase.pending'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('verification.row.crunchbase.request'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets('approved submission renders the Verified pill', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await _renderVerification(
          profile: _profileWith(),
          submissions: <VerificationKind, VerificationRequest>{
            VerificationKind.founderTeamPage: _req(
              VerificationKind.founderTeamPage,
              VerificationStatus.approved,
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const Key('verification.row.team_page.verified'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'Request verification opens the input sheet, submits, and flips to '
        'Pending review', (WidgetTester tester) async {
      final _RecordingVerificationService svc = _RecordingVerificationService();
      // A mutable submission map the provider override reads on each rebuild,
      // so invalidating the provider after submit re-reads the new state.
      final Map<VerificationKind, VerificationRequest> store =
          <VerificationKind, VerificationRequest>{};

      final FakeAuthGateway auth = FakeAuthGateway();
      auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u-1'));
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const VerificationScreen(),
          overrides: <Override>[
            authGatewayProvider.overrideWithValue(auth),
            profileRepositoryProvider
                .overrideWithValue(ProfileRepository(_NoRowRunner())),
            profileProvider.overrideWith(
              (Ref<AsyncValue<Profile?>> _) async => _profileWith(),
            ),
            myVerificationsProvider.overrideWith(
              (Ref<AsyncValue<Map<VerificationKind, VerificationRequest>>>
                      _,) async =>
                  Map<VerificationKind, VerificationRequest>.from(store),
            ),
            verificationServiceProvider.overrideWithValue(svc),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The crunchbase proof captures a URL via the input sheet.
      await tester.tap(
        find.byKey(const Key('verification.row.crunchbase.request')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('verification.inputSheet')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('verification.inputSheet.field')),
        'https://crunchbase.com/person/jane',
      );
      // Mimic the server landing a pending row before the provider re-reads.
      store[VerificationKind.investorCrunchbase] = _req(
        VerificationKind.investorCrunchbase,
        VerificationStatus.pending,
      );
      await tester.tap(find.byKey(const Key('verification.inputSheet.submit')));
      await tester.pumpAndSettle();

      expect(svc.submittedKind, VerificationKind.investorCrunchbase);
      expect(svc.submittedPayload, <String, dynamic>{
        'url': 'https://crunchbase.com/person/jane',
      });
      expect(
        find.byKey(
          const Key('verification.row.crunchbase.pending'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });
  });
}

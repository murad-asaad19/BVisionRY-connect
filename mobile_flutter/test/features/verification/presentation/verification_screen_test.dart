import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/verification/data/verification_service.dart';
import 'package:connect_mobile/features/verification/presentation/verification_screen.dart';
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
  @override
  Future<void> clearGithubVerification() async {
    clearedGithub = true;
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
      if (svc != null) verificationServiceProvider.overrideWithValue(svc),
    ],
  );
}

void main() {
  group('VerificationScreen', () {
    testWidgets('renders GitHub row + disabled rows for other proof types', (
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
      expect(find.textContaining('Coming soon'), findsWidgets);
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
  });
}

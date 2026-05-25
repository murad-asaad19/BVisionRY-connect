import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/onboarding/data/infer_goal_service.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_service.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/providers/handle_availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_supabase.dart';
import '../../helpers/pump.dart';

class _ProfileQ implements ProfileQueryRunner {
  _ProfileQ(this.row);
  Map<String, dynamic>? row;
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => row;
}

class _StubInfer implements InferGoalService {
  @override
  Future<InferGoalResult> infer({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) async {
    return const InferGoalResult(
      goalType: GoalType.hire,
      confidence: InferConfidence.high,
    );
  }
}

class _AvailableRunner implements HandleAvailabilityRunner {
  @override
  Future<bool> check(String handle) async => true;
}

class _RecordingUpdate implements ProfileUpdateRunner {
  int calls = 0;
  String? lastUserId;
  Map<String, dynamic>? lastPatch;

  @override
  Future<void> update({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    calls++;
    lastUserId = userId;
    lastPatch = Map<String, dynamic>.from(patch);
  }
}

Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // The secure-storage plugin used by supabase_flutter doesn't have a
    // platform binding under flutter_test; stub it with a no-op so the auth
    // gateway can initialize without crashing.
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (
      MethodCall call,
    ) async {
      return null;
    });
  });

  testWidgets(
    'full onboarding flow: goal → identity → roles → about → submit',
    (WidgetTester tester) async {
      // Signed in but not onboarded → route guard sends us to /onboarding/goal.
      final FakeAuthGateway auth = FakeAuthGateway();
      auth.pushAuthState(
        AuthChangeEvent.initialSession,
        fakeSession(id: 'user-1'),
      );
      final _ProfileQ profileQ = _ProfileQ(<String, dynamic>{
        'id': 'user-1',
        'onboarded': false,
        'suspended_at': null,
      });
      final _RecordingUpdate updateRunner = _RecordingUpdate();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final LocaleLoader loader = await primedLocaleLoader();

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider
              .overrideWithValue(ProfileRepository(profileQ)),
          onboardingDraftRepositoryProvider
              .overrideWith((_) async => OnboardingDraftRepository(prefs)),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          inferGoalServiceProvider.overrideWithValue(_StubInfer()),
          handleAvailabilityRunnerProvider
              .overrideWithValue(_AvailableRunner()),
          onboardingServiceProvider
              .overrideWithValue(OnboardingService(updateRunner)),
        ],
      );
      addTearDown(() {
        container.dispose();
        auth.close();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(Brightness.light),
            routerConfig: container.read(appRouterProvider),
          ),
        ),
      );
      // pumpAndSettle until the route guard transitions us from sign-in to
      // the onboarding flow and the draft provider hydrates.
      for (int i = 0; i < 5; i++) {
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
      }

      // We should now be on /onboarding/goal — there's exactly one TextField
      // visible (the goal AppInput's inner TextField).
      expect(find.byType(TextField), findsOneWidget,
          reason: 'route guard should have landed on /onboarding/goal');

      // STEP 1 — Goal: type a long goal description so inference fires
      // and the chip auto-selects (high confidence → GoalType.hire).
      await tester.enterText(
        find.byType(TextField),
        'Looking to hire a fractional designer for our healthtech app.',
      );
      // Wait past the 800ms debounce + microtasks.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('goal-next')));
      await tester.pumpAndSettle();

      // STEP 2 — Identity.
      await tester.enterText(
        find.byKey(const ValueKey<String>('identity-name')),
        'Ada Lovelace',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('identity-handle')),
        'ada',
      );
      await _blur(tester);
      await tester.tap(find.byKey(const ValueKey<String>('identity-next')));
      await tester.pumpAndSettle();

      // STEP 3 — Roles.
      await tester.tap(find.byKey(const ValueKey<String>('role-chip-founder')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey<String>('primary-pill-founder')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('roles-next')));
      await tester.pumpAndSettle();

      // STEP 4 — About + submit.
      await tester.enterText(
        find.byKey(const ValueKey<String>('about-city')),
        'Berlin',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('about-country')),
        'Germany',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('about-submit')));
      await tester.pumpAndSettle();

      // Verify the service was called with the assembled draft.
      expect(updateRunner.calls, 1);
      expect(updateRunner.lastUserId, 'user-1');
      final Map<String, dynamic> patch = updateRunner.lastPatch!;
      expect(patch['name'], 'Ada Lovelace');
      expect(patch['handle'], 'ada');
      expect(patch['goal_text'], contains('designer'));
      expect(patch['goal_type'], 'hire');
      expect(patch['roles'], <String>['founder']);
      expect(patch['primary_role'], 'founder');
      expect(patch['city'], 'Berlin');
      expect(patch['country'], 'Germany');
      expect(patch['onboarded'], isTrue);

      // Draft store cleared after success.
      expect(await OnboardingDraftRepository(prefs).read(), isNull);
    },
  );
}

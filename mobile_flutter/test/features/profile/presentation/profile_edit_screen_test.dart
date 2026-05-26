import 'dart:typed_data';

import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/onboarding/data/infer_goal_service.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/profile/data/avatar_upload_service.dart';
import 'package:connect_mobile/features/profile/data/profile_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/pump.dart';

class _NoOpQueryRunner implements ProfileQueryRunner {
  _NoOpQueryRunner(this._row);
  final Map<String, dynamic>? _row;
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => _row;
}

class _RecordingProfileService extends ProfileService {
  _RecordingProfileService() : super(_StubGateway());

  Map<String, dynamic>? lastPatch;
  String? lastUserId;
  Profile? updateResult;

  @override
  Future<Profile> updateProfile({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    lastUserId = userId;
    lastPatch = patch;
    return updateResult ?? Profile.empty(userId);
  }
}

class _StubGateway implements ProfileGateway {
  @override
  Future<Map<String, dynamic>?> fetchById(String id) async => null;
  @override
  Future<Map<String, dynamic>> updateById({
    required String id,
    required Map<String, dynamic> patch,
  }) async =>
      <String, dynamic>{};
  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) async =>
      null;
  @override
  Future<FunctionResponse> invokeFunction(String name, {Object? body}) async =>
      throw UnimplementedError();
}

class _FakeInferService implements InferGoalService {
  int calls = 0;
  String? lastText;

  @override
  Future<InferGoalResult> infer({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) async {
    calls++;
    lastText = text;
    return const InferGoalResult(
      goalType: GoalType.hire,
      confidence: InferConfidence.high,
    );
  }
}

class _FakeAvatarService extends AvatarUploadService {
  _FakeAvatarService()
      : super(source: _NullSource(), storage: _NullStorage(), userId: 'u-1');
}

class _NullSource implements AvatarSource {
  @override
  Future<Uint8List?> pickAndCropSquareAvatar() async => null;
}

class _NullStorage implements AvatarStorageGateway {
  @override
  Future<void> uploadAvatar({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {}
  @override
  String getPublicUrl(String path) => 'https://cdn/$path';
  @override
  Future<void> patchPhotoUrl({
    required String userId,
    required String url,
  }) async {}
}

Profile _baseProfile() => Profile.fromJson(<String, dynamic>{
      'id': 'u-1',
      'handle': 'sara-k',
      'name': 'Sara K',
      'headline': 'Existing headline',
      'bio': 'Existing bio that is long enough.',
      'roles': <String>['founder'],
      'primary_role': 'founder',
      'city': 'Beirut',
      'country': 'LB',
      'goal_type': 'hire',
      'goal_text': 'Looking to hire a backend engineer.',
      'goal_updated_at': '2026-04-01T09:00:00Z',
      'photo_url': null,
      'onboarded': true,
      'verified_github_username': null,
      'verified_github_id': null,
      'verified_at': null,
      'suspended_at': null,
      'private_mode': false,
      'read_receipts_enabled': false,
      'public_investor_page': false,
      'created_at': '2026-01-01T09:00:00Z',
      'updated_at': '2026-04-01T09:00:00Z',
    });

Future<Widget> _renderEditScreen({
  required Profile profile,
  required _RecordingProfileService svc,
  _FakeInferService? infer,
}) async {
  final FakeAuthGateway auth = FakeAuthGateway();
  auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u-1'));
  return wrapWithTheme(
    child: const ProfileEditScreen(),
    overrides: <Override>[
      authGatewayProvider.overrideWithValue(auth),
      profileRepositoryProvider
          .overrideWithValue(ProfileRepository(_NoOpQueryRunner(null))),
      profileProvider
          .overrideWith((Ref<AsyncValue<Profile?>> _) async => profile),
      profileServiceProvider.overrideWithValue(svc),
      avatarUploadServiceProvider.overrideWith(
        (Ref<AvatarUploadService> _) => _FakeAvatarService(),
      ),
      if (infer != null) inferGoalServiceProvider.overrideWithValue(infer),
    ],
  );
}

void main() {
  group('ProfileEditScreen', () {
    testWidgets('handle field is editable with redirect note (D3)', (
      WidgetTester tester,
    ) async {
      final _RecordingProfileService svc = _RecordingProfileService();
      await tester.pumpWidget(
        await _renderEditScreen(profile: _baseProfile(), svc: svc),
      );
      await tester.pumpAndSettle();
      // Gallery D3 (lines 1698-1700): handle is editable and a muted helper
      // line explains the 90-day redirect side effect.
      final TextField handleField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('profileEdit.handle')),
          matching: find.byType(TextField),
        ),
      );
      expect(handleField.enabled, isTrue);
      expect(find.textContaining('90 days'), findsOneWidget);
    });

    testWidgets('Save sends a patch via ProfileService.updateProfile', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(420, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final _RecordingProfileService svc = _RecordingProfileService()
        ..updateResult = _baseProfile().copyWith(headline: 'New headline');
      await tester.pumpWidget(
        await _renderEditScreen(profile: _baseProfile(), svc: svc),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profileEdit.headline')),
        'A brand new headline value here',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('profileEdit.save')));
      await tester.pumpAndSettle();
      expect(svc.lastUserId, 'u-1');
      expect(
        svc.lastPatch?['headline'],
        'A brand new headline value here',
      );
    });

    testWidgets('Save aborts when headline is invalid (3 chars)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(420, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final _RecordingProfileService svc = _RecordingProfileService();
      await tester.pumpWidget(
        await _renderEditScreen(profile: _baseProfile(), svc: svc),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profileEdit.headline')),
        'foo',
      );
      await tester.tap(find.byKey(const Key('profileEdit.save')));
      await tester.pump();
      expect(svc.lastPatch, isNull);
    });

    testWidgets(
      'debounced infer-goal-type re-runs on goal_text edit (≥20 chars)',
      (WidgetTester tester) async {
        // The edit screen is longer than the default test viewport now that
        // it surfaces a Save TopBar action + goal-refresh banner; widen the
        // viewport so the goal_text field is in the rendered tree.
        tester.view.physicalSize = const Size(420, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final _FakeInferService infer = _FakeInferService();
        final _RecordingProfileService svc = _RecordingProfileService();
        await tester.pumpWidget(
          await _renderEditScreen(
            profile: _baseProfile(),
            svc: svc,
            infer: infer,
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('profileEdit.goalText')),
          'I want to hire a senior backend engineer for our payments stack.',
        );
        // Debounce is 800ms.
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pumpAndSettle();
        expect(infer.calls, greaterThan(0));
      },
    );
  });
}

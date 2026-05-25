// ProfileService — own-profile reads, patched updates with column guard,
// privacy + GDPR RPC / edge-function wrappers. Spec §2.2 + §3.1 + §6.11.
//
// We drive the service through a FakeProfileGateway so the tests stay
// hermetic — direct mocking of SupabaseClient gets brittle as the Postgrest
// builder surface evolves.
import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/profile/data/profile_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeGateway implements ProfileGateway {
  Map<String, dynamic>? fetchRow;
  Map<String, dynamic>? updatedRow;
  String? capturedFetchId;
  String? capturedUpdateId;
  Map<String, dynamic>? capturedUpdatePatch;
  String? capturedRpc;
  Map<String, dynamic>? capturedRpcParams;
  Object? rpcResult;
  Object? rpcThrowable;
  Object? updateThrowable;
  String? capturedFunctionName;
  FunctionResponse? functionResponse;

  @override
  Future<Map<String, dynamic>?> fetchById(String id) async {
    capturedFetchId = id;
    return fetchRow;
  }

  @override
  Future<Map<String, dynamic>> updateById({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    capturedUpdateId = id;
    capturedUpdatePatch = patch;
    if (updateThrowable != null) {
      // ignore: only_throw_errors
      throw updateThrowable!;
    }
    return updatedRow ?? <String, dynamic>{'id': id, ...patch};
  }

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) async {
    capturedRpc = name;
    capturedRpcParams = params;
    if (rpcThrowable != null) {
      // ignore: only_throw_errors
      throw rpcThrowable!;
    }
    return rpcResult;
  }

  @override
  Future<FunctionResponse> invokeFunction(String name, {Object? body}) async {
    capturedFunctionName = name;
    return functionResponse ??
        FunctionResponse(status: 200, data: <String, dynamic>{'ok': true});
  }
}

Profile _emptyRow(String id) => Profile.empty(id);

void main() {
  group('ProfileService', () {
    test('fetchOwn returns parsed Profile and forwards the user id', () async {
      final _FakeGateway g = _FakeGateway()
        ..fetchRow = <String, dynamic>{
          'id': 'u-1',
          'handle': 'omar-d',
          'name': 'Omar',
          'onboarded': true,
        };
      final ProfileService svc = ProfileService(g);
      final Profile? p = await svc.fetchOwn('u-1');
      expect(g.capturedFetchId, 'u-1');
      expect(p, isNotNull);
      expect(p!.handle, 'omar-d');
      expect(p.onboarded, isTrue);
    });

    test('fetchOwn returns null when the row is missing', () async {
      final _FakeGateway g = _FakeGateway(); // fetchRow stays null
      final ProfileService svc = ProfileService(g);
      expect(await svc.fetchOwn('missing'), isNull);
    });

    test('updateProfile patches an allowed column and returns the new row',
        () async {
      final _FakeGateway g = _FakeGateway()
        ..updatedRow = <String, dynamic>{
          'id': 'u-1',
          'headline': 'New headline',
          'onboarded': true,
        };
      final ProfileService svc = ProfileService(g);
      final Profile p = await svc.updateProfile(
        userId: 'u-1',
        patch: <String, dynamic>{'headline': 'New headline'},
      );
      expect(g.capturedUpdateId, 'u-1');
      expect(
          g.capturedUpdatePatch, <String, dynamic>{'headline': 'New headline'});
      expect(p.headline, 'New headline');
    });

    test(
        'updateProfile rejects edits to verified_* / suspended_at / onboarded '
        '/ private_mode / public_investor_page columns', () async {
      final _FakeGateway g = _FakeGateway();
      final ProfileService svc = ProfileService(g);

      for (final String col in const <String>[
        'verified_github_username',
        'verified_github_id',
        'verified_at',
        'suspended_at',
        'onboarded',
        'private_mode',
        'public_investor_page',
      ]) {
        expect(
          () => svc.updateProfile(
            userId: 'u-1',
            patch: <String, dynamic>{col: 'whatever'},
          ),
          throwsA(isA<ForbiddenColumnException>()),
          reason: 'should reject $col',
        );
      }
      expect(
        g.capturedUpdatePatch,
        isNull,
        reason: 'gateway must NOT be hit when a forbidden column is present',
      );
    });

    test('updateProfile maps PostgrestException via mapPostgrestError',
        () async {
      final _FakeGateway g = _FakeGateway()
        ..updateThrowable =
            const PostgrestException(message: 'rls denial', code: '42501');
      final ProfileService svc = ProfileService(g);
      expect(
        () => svc.updateProfile(
          userId: 'u-1',
          patch: <String, dynamic>{'headline': 'x'},
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('setPrivateMode calls set_private_mode RPC with bool param', () async {
      final _FakeGateway g = _FakeGateway();
      final ProfileService svc = ProfileService(g);
      await svc.setPrivateMode(true);
      expect(g.capturedRpc, 'set_private_mode');
      expect(g.capturedRpcParams, <String, dynamic>{'p_value': true});
    });

    test('exportMyData calls export_my_data RPC and returns the map', () async {
      final _FakeGateway g = _FakeGateway()
        ..rpcResult = <String, dynamic>{
          'profile': <String, dynamic>{'id': 'u'}
        };
      final ProfileService svc = ProfileService(g);
      final Map<String, dynamic> result = await svc.exportMyData();
      expect(g.capturedRpc, 'export_my_data');
      expect(result.containsKey('profile'), isTrue);
    });

    test(
        'deleteMyAccount invokes the delete-account edge function (NOT the RPC directly)',
        () async {
      final _FakeGateway g = _FakeGateway()
        ..functionResponse =
            FunctionResponse(status: 200, data: <String, dynamic>{'ok': true});
      final ProfileService svc = ProfileService(g);
      await svc.deleteMyAccount();
      expect(g.capturedFunctionName, 'delete-account');
    });

    test('deleteMyAccount surfaces non-2xx as GenericAppException', () async {
      final _FakeGateway g = _FakeGateway()
        ..functionResponse = FunctionResponse(
          status: 500,
          data: <String, dynamic>{'error': 'boom'},
        );
      final ProfileService svc = ProfileService(g);
      expect(
        () => svc.deleteMyAccount(),
        throwsA(isA<AppException>()),
      );
    });

    test('Profile.empty smoke (used by other tests in the suite)', () {
      // Keeps the imports honest if individual tests above are pruned.
      expect(_emptyRow('u').id, 'u');
    });
  });
}

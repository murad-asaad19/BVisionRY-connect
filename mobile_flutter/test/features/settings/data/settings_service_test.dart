// Phase 13 `SettingsService` unit tests. The service is driven through
// the `SettingsGateway` test seam; tests inject a fake to record RPC
// names + params and to throw [PostgrestException]s on the auth path.
import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/settings/data/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeGateway implements SettingsGateway {
  Map<String, Object?> rpcCalls = <String, Object?>{};
  Map<String, dynamic>? lastUpdate;
  String? lastUpdatedUserId;
  String? lastPasswordValue;
  Object? rpcReturn;
  Object? rpcThrowable;
  Object? authThrowable;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) async {
    rpcCalls[name] = params;
    if (rpcThrowable != null) throw rpcThrowable!;
    return rpcReturn;
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    lastUpdatedUserId = userId;
    lastUpdate = patch;
  }

  @override
  String? get currentUserId => 'fixed-user-id';

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    lastPasswordValue = newPassword;
    if (authThrowable != null) throw authThrowable!;
    return UserResponse.fromJson(<String, dynamic>{
      'id': 'fixed-user-id',
      'aud': 'authenticated',
      'created_at': DateTime.now().toIso8601String(),
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
    });
  }
}

void main() {
  late _FakeGateway gateway;
  late SettingsService service;

  setUp(() {
    gateway = _FakeGateway();
    service = SettingsService(gateway);
  });

  test('exportMyData calls export_my_data RPC and returns the JSON map',
      () async {
    gateway.rpcReturn = <String, dynamic>{
      'profile': <String, dynamic>{'name': 'Murad'},
      'intros_sent': <dynamic>[],
    };
    final Map<String, dynamic> out = await service.exportMyData();
    expect(out['profile']['name'], 'Murad');
    expect(gateway.rpcCalls.containsKey('export_my_data'), isTrue);
  });

  test('exportMyData returns empty map when RPC returns null', () async {
    gateway.rpcReturn = null;
    final Map<String, dynamic> out = await service.exportMyData();
    expect(out, isEmpty);
  });

  test('setPrivateMode forwards `p_value` param to set_private_mode RPC',
      () async {
    await service.setPrivateMode(true);
    expect(
      gateway.rpcCalls['set_private_mode'],
      equals(<String, dynamic>{'p_value': true}),
    );
  });

  test('setReadReceiptsEnabled UPDATEs profiles.read_receipts_enabled',
      () async {
    await service.setReadReceiptsEnabled(false);
    expect(
      gateway.lastUpdate,
      equals(<String, dynamic>{'read_receipts_enabled': false}),
    );
    expect(gateway.lastUpdatedUserId, 'fixed-user-id');
  });

  test('setPublicInvestorPage throws UnimplementedRpcException (§17.2)',
      () async {
    expect(
      () => service.setPublicInvestorPage(true),
      throwsA(
        isA<UnimplementedRpcException>()
            .having(
              (UnimplementedRpcException e) => e.i18nKey,
              'i18nKey',
              'settings.publicInvestorPage.comingSoon',
            )
            .having(
              (UnimplementedRpcException e) => e.rpcName,
              'rpcName',
              'set_public_investor_page',
            ),
      ),
    );
  });

  test('changePassword forwards new password to auth.updateUser', () async {
    await service.changePassword('verysecurepass');
    expect(gateway.lastPasswordValue, 'verysecurepass');
  });

  test('changePassword rejects passwords < 8 chars locally', () {
    expect(
      () => service.changePassword('short'),
      throwsA(
        isA<ValidationException>().having(
          (ValidationException e) => e.i18nKey,
          'i18nKey',
          'settings.changePassword.tooShort',
        ),
      ),
    );
    expect(gateway.lastPasswordValue, isNull);
  });
}

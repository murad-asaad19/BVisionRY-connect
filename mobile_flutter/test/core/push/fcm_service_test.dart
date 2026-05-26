import 'dart:async';

import 'package:connect_mobile/core/env.dart';
import 'package:connect_mobile/core/push/fcm_service.dart';
import 'package:connect_mobile/core/push/last_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockMessaging extends Mock implements FirebaseMessagingFacade {}

class _MockGateway extends Mock implements FcmRpcGateway {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    registerFallbackValue(<String, dynamic>{});
  });

  // FcmService gates its public surface on Env.firebaseEnabled — these
  // tests require that flag at compile time, otherwise registerToken()
  // and unregisterToken() short-circuit to `false`. Skip when the suite
  // is invoked without FIREBASE_ENABLED=true.
  final firebaseGate = Env.firebaseEnabled
      ? null
      : 'FcmService tests require --dart-define=FIREBASE_ENABLED=true';

  group('FcmService.registerToken', () {
    test(
        'requests permission, gets token, calls register_device_token RPC, persists',
        skip: firebaseGate, () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      when(() => msg.requestPermission()).thenAnswer((_) async => true);
      when(() => msg.getToken()).thenAnswer((_) async => 'tok-1');
      when(() => msg.platformValue).thenReturn('android');
      when(
        () => rpc.rpc(
          'register_device_token',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async {});

      final FcmService service = FcmService.withGateway(
        messaging: msg,
        gateway: rpc,
        tokenStorage: const LastTokenStorage(),
      );

      expect(await service.registerToken(), isTrue);
      expect(await const LastTokenStorage().get(), equals('tok-1'));
      verify(
        () => rpc.rpc(
          'register_device_token',
          params: <String, dynamic>{
            'p_token': 'tok-1',
            'p_platform': 'android',
          },
        ),
      ).called(1);
    });

    test(
        'permission denied -> returns false, sets permissionDenied, does not call RPC',
        skip: firebaseGate, () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      when(() => msg.requestPermission()).thenAnswer((_) async => false);

      final FcmService service = FcmService.withGateway(
        messaging: msg,
        gateway: rpc,
      );
      expect(await service.registerToken(), isFalse);
      expect(service.permissionDenied, isTrue);
      verifyNever(
        () => rpc.rpc(any(), params: any(named: 'params')),
      );
    });

    test('28000 (token bound to other user) is swallowed + logged', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      when(() => msg.requestPermission()).thenAnswer((_) async => true);
      when(() => msg.getToken()).thenAnswer((_) async => 'tok-shared');
      when(() => msg.platformValue).thenReturn('ios');
      when(
        () => rpc.rpc(any(), params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'token already registered to another account',
          code: '28000',
        ),
      );

      final FcmService service =
          FcmService.withGateway(messaging: msg, gateway: rpc);
      // Must NOT throw - device handoff is expected.
      expect(await service.registerToken(), isFalse);
    });

    test('null/empty token -> returns false without calling RPC', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      when(() => msg.requestPermission()).thenAnswer((_) async => true);
      when(() => msg.getToken()).thenAnswer((_) async => null);

      final FcmService service =
          FcmService.withGateway(messaging: msg, gateway: rpc);
      expect(await service.registerToken(), isFalse);
      verifyNever(
        () => rpc.rpc(any(), params: any(named: 'params')),
      );
    });

    test('non-28000 PostgrestException is also swallowed (logged)', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      when(() => msg.requestPermission()).thenAnswer((_) async => true);
      when(() => msg.getToken()).thenAnswer((_) async => 'tok-x');
      when(() => msg.platformValue).thenReturn('android');
      when(
        () => rpc.rpc(any(), params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(message: 'boom', code: '42501'),
      );

      final FcmService service =
          FcmService.withGateway(messaging: msg, gateway: rpc);
      expect(await service.registerToken(), isFalse);
    });
  });

  group('FcmService.unregisterToken', () {
    test(
        'reads last persisted token, calls unregister_device_token RPC, clears storage',
        () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      await const LastTokenStorage().set('tok-old');
      when(
        () => rpc.rpc(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      final FcmService service =
          FcmService.withGateway(messaging: msg, gateway: rpc);
      await service.unregisterToken();
      verify(
        () => rpc.rpc(
          'unregister_device_token',
          params: <String, dynamic>{'p_token': 'tok-old'},
        ),
      ).called(1);
      expect(await const LastTokenStorage().get(), isNull);
    });

    test('no persisted token -> no-op (no RPC)', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();

      final FcmService service =
          FcmService.withGateway(messaging: msg, gateway: rpc);
      await service.unregisterToken();
      verifyNever(
        () => rpc.rpc(any(), params: any(named: 'params')),
      );
    });

    test('RPC failure still clears local storage', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      await const LastTokenStorage().set('tok-doomed');
      when(
        () => rpc.rpc(any(), params: any(named: 'params')),
      ).thenThrow(Exception('network'));

      final FcmService service =
          FcmService.withGateway(messaging: msg, gateway: rpc);
      await service.unregisterToken();
      expect(await const LastTokenStorage().get(), isNull);
    });
  });

  group('FcmService.subscribeTokenRefresh', () {
    test('re-registers the new token when onTokenRefresh fires', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockGateway rpc = _MockGateway();
      final StreamController<String> controller =
          StreamController<String>.broadcast();
      addTearDown(controller.close);
      when(() => msg.onTokenRefresh).thenAnswer((_) => controller.stream);
      when(() => msg.platformValue).thenReturn('android');
      when(
        () => rpc.rpc(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      final FcmService service =
          FcmService.withGateway(messaging: msg, gateway: rpc);
      service.subscribeTokenRefresh();
      controller.add('tok-2');
      await Future<void>.delayed(const Duration(milliseconds: 1));
      verify(
        () => rpc.rpc(
          'register_device_token',
          params: <String, dynamic>{
            'p_token': 'tok-2',
            'p_platform': 'android',
          },
        ),
      ).called(1);
      expect(await const LastTokenStorage().get(), equals('tok-2'));
      await service.dispose();
    });
  });
}

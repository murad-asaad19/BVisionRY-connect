import 'dart:async';

import 'package:connect_mobile/core/push/fcm_service.dart';
import 'package:connect_mobile/core/push/last_token_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockMessaging extends Mock implements FirebaseMessagingFacade {}

class _MockSupabase extends Mock implements SupabaseClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('FcmService.registerToken', () {
    test(
        'requests permission, gets token, calls register_device_token RPC, persists',
        () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();
      when(() => msg.requestPermission()).thenAnswer((_) async => true);
      when(() => msg.getToken()).thenAnswer((_) async => 'tok-1');
      when(() => msg.platformValue).thenReturn('android');
      when(
        () => sb.rpc<dynamic>(
          'register_device_token',
          params: <String, dynamic>{
            'p_token': 'tok-1',
            'p_platform': 'android',
          },
        ),
      ).thenAnswer((_) async => null);

      final FcmService service = FcmService(
        messaging: msg,
        supabase: sb,
        tokenStorage: const LastTokenStorage(),
      );

      expect(await service.registerToken(), isTrue);
      expect(await const LastTokenStorage().get(), equals('tok-1'));
      verify(
        () => sb.rpc<dynamic>(
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
        () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();
      when(() => msg.requestPermission()).thenAnswer((_) async => false);

      final FcmService service = FcmService(
        messaging: msg,
        supabase: sb,
      );
      expect(await service.registerToken(), isFalse);
      expect(service.permissionDenied, isTrue);
      verifyNever(() =>
          sb.rpc<dynamic>(any(), params: any(named: 'params')));
    });

    test('28000 (token bound to other user) is swallowed + logged', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();
      when(() => msg.requestPermission()).thenAnswer((_) async => true);
      when(() => msg.getToken()).thenAnswer((_) async => 'tok-shared');
      when(() => msg.platformValue).thenReturn('ios');
      when(
        () => sb.rpc<dynamic>(
          'register_device_token',
          params: any(named: 'params'),
        ),
      ).thenThrow(
        const PostgrestException(
          message: 'token already registered to another account',
          code: '28000',
        ),
      );

      final FcmService service = FcmService(messaging: msg, supabase: sb);
      // Must NOT throw - device handoff is expected.
      expect(await service.registerToken(), isFalse);
    });

    test('null/empty token -> returns false without calling RPC', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();
      when(() => msg.requestPermission()).thenAnswer((_) async => true);
      when(() => msg.getToken()).thenAnswer((_) async => null);

      final FcmService service = FcmService(messaging: msg, supabase: sb);
      expect(await service.registerToken(), isFalse);
      verifyNever(() =>
          sb.rpc<dynamic>(any(), params: any(named: 'params')));
    });
  });

  group('FcmService.unregisterToken', () {
    test(
        'reads last persisted token, calls unregister_device_token RPC, clears storage',
        () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();
      await const LastTokenStorage().set('tok-old');
      when(
        () => sb.rpc<dynamic>(
          'unregister_device_token',
          params: <String, dynamic>{'p_token': 'tok-old'},
        ),
      ).thenAnswer((_) async => null);

      final FcmService service = FcmService(messaging: msg, supabase: sb);
      await service.unregisterToken();
      verify(
        () => sb.rpc<dynamic>(
          'unregister_device_token',
          params: <String, dynamic>{'p_token': 'tok-old'},
        ),
      ).called(1);
      expect(await const LastTokenStorage().get(), isNull);
    });

    test('no persisted token -> no-op (no RPC)', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();

      final FcmService service = FcmService(messaging: msg, supabase: sb);
      await service.unregisterToken();
      verifyNever(() =>
          sb.rpc<dynamic>(any(), params: any(named: 'params')));
    });

    test('RPC failure still clears local storage', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();
      await const LastTokenStorage().set('tok-doomed');
      when(
        () => sb.rpc<dynamic>(
          'unregister_device_token',
          params: any(named: 'params'),
        ),
      ).thenThrow(Exception('network'));

      final FcmService service = FcmService(messaging: msg, supabase: sb);
      await service.unregisterToken();
      expect(await const LastTokenStorage().get(), isNull);
    });
  });

  group('FcmService.subscribeTokenRefresh', () {
    test('re-registers the new token when onTokenRefresh fires', () async {
      final _MockMessaging msg = _MockMessaging();
      final _MockSupabase sb = _MockSupabase();
      final StreamController<String> controller =
          StreamController<String>.broadcast();
      addTearDown(controller.close);
      when(() => msg.onTokenRefresh).thenAnswer((_) => controller.stream);
      when(() => msg.platformValue).thenReturn('android');
      when(
        () => sb.rpc<dynamic>(
          'register_device_token',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => null);

      final FcmService service = FcmService(messaging: msg, supabase: sb);
      service.subscribeTokenRefresh();
      controller.add('tok-2');
      await Future<void>.delayed(const Duration(milliseconds: 1));
      verify(
        () => sb.rpc<dynamic>(
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

import 'package:connect_mobile/features/auth/data/auth_service.dart';
import 'package:connect_mobile/features/push/data/fcm_token_store.dart';
import 'package:connect_mobile/features/settings/data/persisted_stores.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('sendMagicLink', () {
    test('calls auth.signInWithOtp with redirect URI', () async {
      final auth = FakeAuthGateway();
      String? capturedEmail;
      String? capturedRedirect;
      auth.onOtp =
          ({required String email, required String emailRedirectTo}) async {
        capturedEmail = email;
        capturedRedirect = emailRedirectTo;
      };
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      await svc.sendMagicLink('a@b.com');
      expect(capturedEmail, 'a@b.com');
      expect(capturedRedirect, equals('connect-mobile://auth'));
    });

    test('trims whitespace and lowercases', () async {
      final auth = FakeAuthGateway();
      String? captured;
      auth.onOtp =
          ({required String email, required String emailRedirectTo}) async {
        captured = email;
      };
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      await svc.sendMagicLink('  A@B.com  ');
      expect(captured, 'a@b.com');
    });
  });

  group('signUpWithPassword', () {
    test('calls auth.signUp with redirect and normalised email', () async {
      final auth = FakeAuthGateway();
      String? capEmail;
      String? capPwd;
      String? capRedirect;
      auth.onSignUp = ({
        required String email,
        required String password,
        required String emailRedirectTo,
      }) async {
        capEmail = email;
        capPwd = password;
        capRedirect = emailRedirectTo;
        return AuthResponse(
          session: fakeSession(),
          user: fakeSession().user,
        );
      };
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      await svc.signUpWithPassword(email: '  X@Y.com', password: 'Pw345678');
      expect(capEmail, 'x@y.com');
      expect(capPwd, 'Pw345678');
      expect(capRedirect, 'connect-mobile://auth');
    });

    test('rejects passwords shorter than 8', () async {
      final svc = AuthService(
        auth: FakeAuthGateway(),
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      expect(
        () => svc.signUpWithPassword(email: 'a@b.com', password: 'short'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('signInWithEmailPassword', () {
    test('passes normalised email through', () async {
      final auth = FakeAuthGateway();
      String? capEmail;
      String? capPwd;
      auth.onSignIn =
          ({required String email, required String password}) async {
        capEmail = email;
        capPwd = password;
        return AuthResponse(session: fakeSession(), user: fakeSession().user);
      };
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      await svc.signInWithEmailPassword(
        email: ' A@B.com ',
        password: 'pw345678',
      );
      expect(capEmail, 'a@b.com');
      expect(capPwd, 'pw345678');
    });
  });

  group('signInWithIdentifier', () {
    test('routes "user@example.com" to email path', () async {
      final auth = FakeAuthGateway();
      auth.onSignIn =
          ({required String email, required String password}) async {
        expect(email, 'user@example.com');
        return AuthResponse(session: fakeSession(), user: fakeSession().user);
      };
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      await svc.signInWithIdentifier(
        identifier: 'user@example.com',
        password: 'pw345678',
      );
    });

    test('routes "@murad" to handle-login edge function', () async {
      final auth = FakeAuthGateway();
      final fn = FakeFunctionsGateway();
      String? fnName;
      Object? fnBody;
      fn.onInvoke = (String name, {Object? body}) async {
        fnName = name;
        fnBody = body;
        return FunctionResponse(
          status: 200,
          data: <String, dynamic>{
            'access_token': 'tok-a',
            'refresh_token': 'tok-r',
            'expires_in': 3600,
            'token_type': 'bearer',
          },
        );
      };
      String? capAccess;
      String? capRefresh;
      auth.onSetSession =
          ({required String accessToken, required String refreshToken}) async {
        capAccess = accessToken;
        capRefresh = refreshToken;
        return AuthResponse(
          session: fakeSession(),
          user: fakeSession().user,
        );
      };
      final svc = AuthService(
        auth: auth,
        functions: fn,
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      await svc.signInWithIdentifier(
        identifier: '@murad',
        password: 'pw345678',
      );
      expect(fnName, 'auth-handle-login');
      expect((fnBody! as Map)['handle'], 'murad');
      expect((fnBody! as Map)['password'], 'pw345678');
      expect(capAccess, 'tok-a');
      expect(capRefresh, 'tok-r');
    });

    test('non-200 edge response throws AuthException with 401 body', () async {
      final fn = FakeFunctionsGateway();
      fn.onInvoke = (String name, {Object? body}) async => FunctionResponse(
            status: 401,
            data: <String, dynamic>{'error': 'invalid_credentials'},
          );
      final svc = AuthService(
        auth: FakeAuthGateway(),
        functions: fn,
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      expect(
        () => svc.signInWithIdentifier(
          identifier: 'murad',
          password: 'pw345678',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('createSessionFromUrl', () {
    test('PKCE: extracts code and calls exchangeCodeForSession', () async {
      final auth = FakeAuthGateway();
      String? capCode;
      auth.onExchange = (String code) async {
        capCode = code;
        return AuthSessionUrlResponse(
          session: fakeSession(),
          redirectType: 'recovery',
        );
      };
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      final session = await svc.createSessionFromUrl(
        Uri.parse('connect-mobile://auth?code=abc-123'),
      );
      expect(capCode, 'abc-123');
      expect(session, isNotNull);
    });

    test('implicit: parses #access_token & refresh_token then setSession',
        () async {
      final auth = FakeAuthGateway();
      String? capA;
      String? capR;
      auth.onSetSession =
          ({required String accessToken, required String refreshToken}) async {
        capA = accessToken;
        capR = refreshToken;
        return AuthResponse(
          session: fakeSession(),
          user: fakeSession().user,
        );
      };
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      final url = Uri.parse(
        'connect-mobile://auth#access_token=AAA&refresh_token=RRR&token_type=bearer',
      );
      final s = await svc.createSessionFromUrl(url);
      expect(capA, 'AAA');
      expect(capR, 'RRR');
      expect(s, isNotNull);
    });

    test('bare /auth → returns null without side effect', () async {
      final auth = FakeAuthGateway();
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      final s = await svc.createSessionFromUrl(
        Uri.parse('connect-mobile://auth'),
      );
      expect(s, isNull);
    });
  });

  group('signOut', () {
    test(
        'deregisters FCM token before signOut, clears stores, opt-out telemetry',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'connect.fcm_last_token': 'fcm-tok-123',
        'connect.feed_filters': 'x',
        'connect.profile_nudge': 'x',
        'connect.onboarding_draft': 'x',
        'connect.telemetry_consent': true,
      });

      final auth = FakeAuthGateway();
      final order = <String>[];
      auth.onSignOut = ({SignOutScope scope = SignOutScope.local}) async {
        order.add('signOut:${scope.name}');
      };

      final tokens = FcmTokenStore();
      String? deregistered;
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: tokens,
        stores: PersistedStores(),
        deregisterFcm: (String t) async {
          order.add('deregister:$t');
          deregistered = t;
        },
      );

      await svc.signOut();

      expect(order.first, 'deregister:fcm-tok-123');
      expect(order.last, 'signOut:local');
      expect(deregistered, 'fcm-tok-123');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('connect.fcm_last_token'), isNull);
      expect(prefs.getString('connect.feed_filters'), isNull);
      expect(prefs.getString('connect.profile_nudge'), isNull);
      expect(prefs.getString('connect.onboarding_draft'), isNull);
      expect(prefs.getBool('connect.telemetry_consent'), isFalse);
    });

    test('proceeds when no token stored and no deregister callback', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final auth = FakeAuthGateway();
      auth.onSignOut = ({SignOutScope scope = SignOutScope.local}) async {};
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
      );
      await svc.signOut();
    });

    test('continues sign-out even if deregister throws', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'connect.fcm_last_token': 'tok',
      });
      final auth = FakeAuthGateway();
      var called = false;
      auth.onSignOut =
          ({SignOutScope scope = SignOutScope.local}) async => called = true;
      final svc = AuthService(
        auth: auth,
        functions: FakeFunctionsGateway(),
        tokens: FcmTokenStore(),
        stores: PersistedStores(),
        deregisterFcm: (String t) async => throw Exception('network'),
      );
      await svc.signOut();
      expect(called, isTrue);
    });
  });
}

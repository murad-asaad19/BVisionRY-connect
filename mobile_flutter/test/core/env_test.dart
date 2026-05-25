import 'package:connect_mobile/core/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateProdConfig', () {
    test('no-op when sentryEnv is not prod', () {
      // None should throw; all values placeholder-ish
      validateProdConfig(
        sentryEnv: 'dev',
        supabaseUrl: '',
        supabaseAnonKey: '',
        appLinksHost: 'DOMAIN_PLACEHOLDER',
        easProjectId: 'PROJECT_ID_PLACEHOLDER',
      );
    });

    test('throws when appLinksHost is placeholder in prod', () {
      expect(
        () => validateProdConfig(
          sentryEnv: 'prod',
          supabaseUrl: 'https://x.supabase.co',
          supabaseAnonKey: 'anon',
          appLinksHost: 'DOMAIN_PLACEHOLDER',
          easProjectId: 'eas123',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when easProjectId is placeholder in prod', () {
      expect(
        () => validateProdConfig(
          sentryEnv: 'prod',
          supabaseUrl: 'https://x.supabase.co',
          supabaseAnonKey: 'anon',
          appLinksHost: 'connect.bvisionry.com',
          easProjectId: 'PROJECT_ID_PLACEHOLDER',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when supabaseUrl is empty in prod', () {
      expect(
        () => validateProdConfig(
          sentryEnv: 'prod',
          supabaseUrl: '',
          supabaseAnonKey: 'anon',
          appLinksHost: 'connect.bvisionry.com',
          easProjectId: 'eas123',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when supabaseAnonKey is empty in prod', () {
      expect(
        () => validateProdConfig(
          sentryEnv: 'prod',
          supabaseUrl: 'https://x.supabase.co',
          supabaseAnonKey: '',
          appLinksHost: 'connect.bvisionry.com',
          easProjectId: 'eas123',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('no-op when all prod requirements satisfied', () {
      validateProdConfig(
        sentryEnv: 'prod',
        supabaseUrl: 'https://x.supabase.co',
        supabaseAnonKey: 'anon-key',
        appLinksHost: 'connect.bvisionry.com',
        easProjectId: 'eas123',
      );
    });
  });

  test('Env constants have expected defaults', () {
    expect(Env.supabaseUrl, isA<String>());
    expect(Env.supabaseAnonKey, isA<String>());
    expect(Env.appScheme, equals('connect-mobile'));
    expect(Env.firebaseEnabled, isA<bool>());
    expect(Env.sentryEnv, equals('dev')); // default when not provided
  });
}

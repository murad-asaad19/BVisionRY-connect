import 'package:connect_mobile/core/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Env reads dart-defines with sensible defaults', () {
    // Types resolve from String.fromEnvironment / bool.fromEnvironment; values
    // depend on --dart-define flags at compile time.
    expect(Env.supabaseUrl, isA<String>());
    expect(Env.supabaseAnonKey, isA<String>());
    expect(Env.appScheme, equals('connect-mobile'));
    expect(Env.firebaseEnabled, isA<bool>());
    expect(Env.appLinksHost, equals('DOMAIN_PLACEHOLDER'));
    expect(Env.easProjectId, equals('PROJECT_ID_PLACEHOLDER'));
    expect(Env.sentryEnv, equals('dev'));
  });

  test(
    'Env.requireProd throws when app links host is placeholder',
    () {
      expect(
        () => Env.requireProdInvariants(),
        throwsA(isA<StateError>()),
      );
    },
    skip: Env.sentryEnv != 'prod',
  );
}

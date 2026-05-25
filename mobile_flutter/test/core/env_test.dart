import 'package:connect_mobile/core/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Env reads dart-defines and throws in prod when required keys missing', () {
    expect(Env.supabaseUrl, isNotEmpty);
    expect(Env.supabaseAnonKey, isNotEmpty);
    expect(Env.appScheme, equals('connect-mobile'));
    expect(Env.firebaseEnabled, isA<bool>());
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

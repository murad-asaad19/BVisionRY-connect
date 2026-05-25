import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntroState', () {
    test('fromJson covers all 5 values', () {
      expect(IntroState.fromJson('delivered'), IntroState.delivered);
      expect(IntroState.fromJson('accepted'), IntroState.accepted);
      expect(IntroState.fromJson('declined'), IntroState.declined);
      expect(IntroState.fromJson('expired'), IntroState.expired);
      expect(IntroState.fromJson('connected'), IntroState.connected);
    });

    test('toJson round-trips', () {
      for (final s in IntroState.values) {
        expect(IntroState.fromJson(s.toJson()), s);
      }
    });

    test('fromJson throws on unknown value', () {
      expect(() => IntroState.fromJson('bogus'), throwsA(isA<ArgumentError>()));
    });
  });

  group('IntroKind', () {
    test('covers direct/warm_request/warm_forward', () {
      expect(IntroKind.fromJson('direct'), IntroKind.direct);
      expect(IntroKind.fromJson('warm_request'), IntroKind.warmRequest);
      expect(IntroKind.fromJson('warm_forward'), IntroKind.warmForward);
    });

    test('toJson uses snake_case wire strings', () {
      expect(IntroKind.direct.toJson(), 'direct');
      expect(IntroKind.warmRequest.toJson(), 'warm_request');
      expect(IntroKind.warmForward.toJson(), 'warm_forward');
    });

    test('round-trips for every value', () {
      for (final k in IntroKind.values) {
        expect(IntroKind.fromJson(k.toJson()), k);
      }
    });

    test('fromJson throws on unknown value', () {
      expect(
        () => IntroKind.fromJson('mystery'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

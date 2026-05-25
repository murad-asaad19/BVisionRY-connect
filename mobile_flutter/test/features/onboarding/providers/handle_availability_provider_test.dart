import 'package:connect_mobile/features/onboarding/providers/handle_availability_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRunner implements HandleAvailabilityRunner {
  _FakeRunner(this._answer);
  final Future<bool> Function(String handle) _answer;
  int calls = 0;
  String? lastHandle;

  @override
  Future<bool> check(String handle) async {
    calls++;
    lastHandle = handle;
    return _answer(handle);
  }
}

void main() {
  ProviderContainer makeContainer(HandleAvailabilityRunner runner) {
    return ProviderContainer(
      overrides: <Override>[
        handleAvailabilityRunnerProvider.overrideWithValue(runner),
      ],
    );
  }

  test('returns true when RPC reports available', () async {
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    final ProviderContainer c = makeContainer(runner);
    addTearDown(c.dispose);
    final bool? result =
        await c.read(handleAvailabilityProvider('ada').future);
    expect(result, isTrue);
    expect(runner.calls, 1);
    expect(runner.lastHandle, 'ada');
  });

  test('returns false when RPC reports taken', () async {
    final _FakeRunner runner = _FakeRunner((String h) async => false);
    final ProviderContainer c = makeContainer(runner);
    addTearDown(c.dispose);
    expect(
      await c.read(handleAvailabilityProvider('taken').future),
      isFalse,
    );
  });

  test('returns null without calling RPC when handle is empty', () async {
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    final ProviderContainer c = makeContainer(runner);
    addTearDown(c.dispose);
    expect(await c.read(handleAvailabilityProvider('').future), isNull);
    expect(runner.calls, 0);
  });

  test('returns null without calling RPC when handle fails format check',
      () async {
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    final ProviderContainer c = makeContainer(runner);
    addTearDown(c.dispose);
    // 'Ada' is uppercase → fails the lowercase regex; should not hit RPC.
    expect(await c.read(handleAvailabilityProvider('Ada').future), isNull);
    expect(runner.calls, 0);
  });

  test('two distinct handles each issue their own RPC call', () async {
    final _FakeRunner runner = _FakeRunner((String h) async => h == 'ada');
    final ProviderContainer c = makeContainer(runner);
    addTearDown(c.dispose);
    final bool? a = await c.read(handleAvailabilityProvider('ada').future);
    final bool? b = await c.read(handleAvailabilityProvider('bob').future);
    expect(a, isTrue);
    expect(b, isFalse);
    expect(runner.calls, 2);
  });

  test('same handle is cached by Riverpod family (one RPC call)', () async {
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    final ProviderContainer c = makeContainer(runner);
    addTearDown(c.dispose);
    await c.read(handleAvailabilityProvider('ada').future);
    await c.read(handleAvailabilityProvider('ada').future);
    expect(runner.calls, 1);
  });

  test('propagates errors from the runner', () async {
    final _FakeRunner runner = _FakeRunner((String h) async {
      throw Exception('network');
    });
    final ProviderContainer c = makeContainer(runner);
    addTearDown(c.dispose);
    expect(
      () => c.read(handleAvailabilityProvider('ada').future),
      throwsA(isA<Exception>()),
    );
  });
}

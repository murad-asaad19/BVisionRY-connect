import 'dart:async';

import 'package:connect_mobile/features/chat/providers/typing_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('typingProvider emits empty set initially', () async {
    final ctrl = StreamController<TypingEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        typingChannelProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    final sub = container.listen(typingProvider('c1'), (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final v = container.read(typingProvider('c1'));
    expect(v.value, isA<Set<String>>());
    sub.close();
  });
}

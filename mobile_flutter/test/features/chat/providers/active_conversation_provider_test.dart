import 'package:connect_mobile/features/chat/providers/active_conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to null and accepts updates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(activeConversationProvider), isNull);
    container.read(activeConversationProvider.notifier).state = 'c1';
    expect(container.read(activeConversationProvider), 'c1');
    container.read(activeConversationProvider.notifier).state = null;
    expect(container.read(activeConversationProvider), isNull);
  });
}

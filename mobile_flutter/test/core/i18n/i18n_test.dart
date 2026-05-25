import 'package:connect_mobile/core/i18n/i18n.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('context.t resolves a key from the active locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (BuildContext ctx, WidgetRef ref, _) {
              final AsyncValue<void> ready = ref.watch(localeReadyProvider);
              return ready.when(
                loading: () => const SizedBox.shrink(),
                error: (Object err, StackTrace st) => Text('err: $err'),
                data: (_) => Builder(
                  builder: (BuildContext c) => Text(c.t('common.cancel')),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp('[A-Za-z]')), findsOneWidget);
  });
}

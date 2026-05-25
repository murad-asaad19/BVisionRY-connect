import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConfirmService.confirm resolves true when user taps confirm',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(confirmServiceProvider);

    late Future<bool> result;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Builder(
            builder: (ctx) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    result = service.confirm(
                      ctx,
                      title: 'Delete intro?',
                      body: 'This cannot be undone.',
                      confirmLabel: 'Delete',
                      destructive: true,
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Delete intro?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('ConfirmService.confirm resolves false when cancelled',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(confirmServiceProvider);

    late Future<bool> result;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Builder(
            builder: (ctx) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    result = service.confirm(
                      ctx,
                      title: 'Sign out?',
                      confirmLabel: 'Sign out',
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });
}

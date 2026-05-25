import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/toast.dart';
import 'package:connect_mobile/core/widgets/variants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ToastHost renders queued toasts and dismisses on tap',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(body: ToastHost()),
        ),
      ),
    );

    container
        .read(toastServiceProvider.notifier)
        .showToast(title: 'Saved', intent: AppIntent.success);
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);

    // Tap to dismiss.
    await tester.tap(find.text('Saved'));
    await tester.pump();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('ToastHost auto-dismisses after 3.5s', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(body: ToastHost()),
        ),
      ),
    );

    container
        .read(toastServiceProvider.notifier)
        .showToast(title: 'Ephemeral', intent: AppIntent.info);
    await tester.pump();
    expect(find.text('Ephemeral'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3600));
    expect(find.text('Ephemeral'), findsNothing);
  });

  testWidgets('ToastService maps intents to icons', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(body: ToastHost()),
        ),
      ),
    );

    container
        .read(toastServiceProvider.notifier)
        .showToast(title: 'Ok', intent: AppIntent.success);
    container
        .read(toastServiceProvider.notifier)
        .showToast(title: 'Bad', intent: AppIntent.danger);
    container
        .read(toastServiceProvider.notifier)
        .showToast(title: 'Warn', intent: AppIntent.warning);
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // Drain timers so the test can settle cleanly.
    await tester.pump(const Duration(milliseconds: 3600));
  });
}

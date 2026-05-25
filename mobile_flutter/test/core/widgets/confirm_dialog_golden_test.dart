import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('ConfirmSheet variants', (tester) async {
    Future<void> render({required bool destructive}) async {
      final container = ProviderContainer();
      final service = container.read(confirmServiceProvider);

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
                      service.confirm(
                        ctx,
                        title: destructive ? 'Delete intro?' : 'Sign out?',
                        body: destructive
                            ? 'This cannot be undone.'
                            : 'You can sign back in anytime.',
                        confirmLabel: destructive ? 'Delete' : 'Sign out',
                        destructive: destructive,
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
    }

    await render(destructive: true);
    await screenMatchesGolden(tester, 'confirm_dialog_destructive');

    await render(destructive: false);
    await screenMatchesGolden(tester, 'confirm_dialog_default');
  });
}

import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/toast.dart';
import 'package:connect_mobile/core/widgets/variants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('Toast intent variants', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(toastServiceProvider.notifier);
    notifier.showToast(
      title: 'Saved successfully',
      body: 'Your changes are live.',
      intent: AppIntent.success,
    );
    notifier.showToast(
      title: 'Could not save',
      body: 'Network unreachable. Try again.',
      intent: AppIntent.danger,
    );
    notifier.showToast(
      title: 'Heads up',
      intent: AppIntent.warning,
    );
    notifier.showToast(
      title: 'New invite waiting',
      intent: AppIntent.info,
    );

    await tester.pumpWidgetBuilder(
      UncontrolledProviderScope(
        container: container,
        child: const ToastHost(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 480),
    );
    await screenMatchesGolden(tester, 'toast_intents');
    // Let any pending dismiss timers fire before the test exits.
    await tester.pump(const Duration(milliseconds: 3600));
  });
}

import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('EmptyState variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'icon-title',
        const EmptyState(icon: Icons.inbox_outlined, title: 'Nothing here yet'),
      )
      ..addScenario(
        'with-body',
        const EmptyState(
          icon: Icons.search,
          title: 'No results',
          body: 'Try widening your search radius.',
        ),
      )
      ..addScenario(
        'with-action',
        EmptyState(
          icon: Icons.mail_outline,
          title: 'Inbox is empty',
          body: 'Connect with someone to start a conversation.',
          action: EmptyStateAction(label: 'Find people', onPressed: () {}),
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 1100),
    );
    await screenMatchesGolden(tester, 'empty_state_variants');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);

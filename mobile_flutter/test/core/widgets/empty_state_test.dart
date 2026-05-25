import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState renders icon, title, and body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here yet',
            body: 'Once you send an intro it will appear here.',
          ),
        ),
      ),
    );
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Once you send an intro it will appear here.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('EmptyState fires action callback when pressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: EmptyState(
            icon: Icons.search,
            title: 'No results',
            action: EmptyStateAction(
              label: 'Refresh',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Refresh'));
    expect(tapped, isTrue);
  });
}

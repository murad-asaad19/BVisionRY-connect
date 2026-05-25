import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsRow renders label + description + chevron',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SettingsRow(
            label: 'Profile',
            description: 'View and edit your profile',
            icon: Icons.person,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('View and edit your profile'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('SettingsRow fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SettingsRow(label: 'Sign out', onTap: () => tapped = true),
        ),
      ),
    );
    await tester.tap(find.text('Sign out'));
    expect(tapped, isTrue);
  });

  testWidgets('SettingsRow destructive colours label danger', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SettingsRow(
            label: 'Delete account',
            icon: Icons.delete,
            destructive: true,
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Delete account'));
    expect(text.style?.color, const Color(0xFFB91C1C));
  });

  testWidgets('SettingsRow trailing replaces chevron', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SettingsRow(
            label: 'Notifications',
            trailing: const Text('On'),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('On'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}

import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/presentation/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders wordmark and child', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const AuthShell(child: Text('FORM-CHILD')),
      ),
    );
    expect(find.text('BVisionRY'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('FORM-CHILD'), findsOneWidget);
  });

  testWidgets('hero gradient runs navy then navyLight', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const AuthShell(child: SizedBox(height: 40)),
      ),
    );
    final Container container = tester.widget<Container>(
      find.byKey(const Key('auth-shell-hero')),
    );
    final BoxDecoration deco = container.decoration! as BoxDecoration;
    final LinearGradient gradient = deco.gradient! as LinearGradient;
    expect(gradient.colors.first, const Color(0xFF0F3460));
    expect(gradient.colors.last, const Color(0xFF1A4A80));
  });

  testWidgets('renders optional tagline when supplied', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const AuthShell(
          tagline: 'Where deals meet talent',
          child: SizedBox(height: 40),
        ),
      ),
    );
    expect(find.text('Where deals meet talent'), findsOneWidget);
  });
}

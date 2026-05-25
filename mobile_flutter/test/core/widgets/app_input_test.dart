import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppInput emits onChanged when user types', (tester) async {
    String captured = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppInput(
            label: 'Headline',
            value: '',
            onChanged: (s) => captured = s,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Hello world');
    expect(captured, 'Hello world');
  });

  testWidgets('AppInput shows label and error text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: AppInput(
            label: 'Email',
            value: 'bad',
            errorText: 'Invalid email',
          ),
        ),
      ),
    );
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('Invalid email'), findsOneWidget);
  });

  testWidgets('AppInput uses danger border when errorText is set',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: AppInput(value: '', errorText: 'Required'),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('app-input-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, const Color(0xFFEF4444));
  });
}

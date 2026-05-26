import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/settings/presentation/widgets/coming_soon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ComingSoonCard renders title + body text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: ComingSoonCard(
            title: 'Soon',
            body: 'Ships next release',
          ),
        ),
      ),
    );
    expect(find.text('Soon'), findsOneWidget);
    expect(find.text('Ships next release'), findsOneWidget);
  });
}

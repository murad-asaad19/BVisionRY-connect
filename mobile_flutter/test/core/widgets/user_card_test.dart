import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UserCard renders name + role + headline + location',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: UserCard(
            name: 'Ada Lovelace',
            primaryRole: 'Founder',
            headline: 'Building rails for autonomous agents.',
            city: 'London',
            country: 'UK',
          ),
        ),
      ),
    );
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Founder'), findsOneWidget);
    expect(find.text('Building rails for autonomous agents.'), findsOneWidget);
    expect(find.text('London · UK'), findsOneWidget);
  });

  testWidgets('UserCard shows verified badge when verified=true',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: UserCard(
            name: 'Ada',
            primaryRole: 'Founder',
            verified: true,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('UserCard omits verified badge when verified=false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: UserCard(name: 'Ada', primaryRole: 'Founder'),
        ),
      ),
    );
    expect(find.byIcon(Icons.verified), findsNothing);
  });

  testWidgets('UserCard fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: UserCard(
            name: 'Ada',
            primaryRole: 'Founder',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ada'));
    expect(tapped, isTrue);
  });
}

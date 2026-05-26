import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/pill.dart';
import 'package:connect_mobile/core/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UserCard renders name, role line, headline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: UserCard(
            name: 'Ada Lovelace',
            primaryRole: 'founder',
            headline: 'Building rails for autonomous agents.',
            city: 'London',
            country: 'UK',
          ),
        ),
      ),
    );
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Founder · London · UK'), findsOneWidget);
    expect(find.text('Building rails for autonomous agents.'), findsOneWidget);
  });

  testWidgets('UserCard renders inline verified pill when verified=true',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: UserCard(
            name: 'Ada',
            primaryRole: 'builder',
            verified: true,
          ),
        ),
      ),
    );
    expect(find.byType(Pill), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    // "Builder" appears twice: once in the verified pill, once at the
    // start of the muted role line.
    expect(find.text('Builder'), findsNWidgets(2));
  });

  testWidgets('UserCard omits verified pill when verified=false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: UserCard(name: 'Ada', primaryRole: 'builder'),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('UserCard renders reason slot below headline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: UserCard(
            name: 'Ada',
            primaryRole: 'builder',
            headline: 'Building stuff',
            reason: Text('Match: payments-infra'),
          ),
        ),
      ),
    );
    expect(find.text('Match: payments-infra'), findsOneWidget);
  });

  testWidgets('UserCard fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: UserCard(
            name: 'Ada',
            primaryRole: 'founder',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ada'));
    expect(tapped, isTrue);
  });
}

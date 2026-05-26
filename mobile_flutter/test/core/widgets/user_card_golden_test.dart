import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('UserCard variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'minimal',
        const UserCard(name: 'Ada Lovelace', primaryRole: 'founder'),
      )
      ..addScenario(
        'full row',
        UserCard(
          name: 'Ada Lovelace',
          primaryRole: 'founder',
          headline:
              'Building rails for autonomous agents. Hiring eng + design.',
          city: 'London',
          country: 'UK',
          verified: true,
          onTap: () {},
        ),
      )
      ..addScenario(
        'featured + reason',
        const UserCard(
          name: 'Grace Hopper',
          primaryRole: 'builder',
          headline: 'Compiler theory + naval comms.',
          city: 'New York',
          country: 'USA',
          verified: true,
          featured: true,
          reason: Text(
            'Match: compiler-systems overlap',
            style: TextStyle(fontSize: 10),
          ),
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 800),
    );
    await screenMatchesGolden(tester, 'user_card_variants');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(12), child: child);

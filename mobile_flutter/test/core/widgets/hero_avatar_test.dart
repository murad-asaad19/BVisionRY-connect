import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/hero_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HeroAvatar wraps Avatar in a Hero with a deterministic tag',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: const Scaffold(
        body: HeroAvatar(userId: 'user-123', photoUrl: null, name: 'Ana'),
      ),
    ));
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, equals('avatar-user-123'));
  });
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Avatar renders initials when photoUrl is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: Avatar(name: 'Ada Lovelace'),
        ),
      ),
    );
    expect(find.text('AL'), findsOneWidget);
  });

  testWidgets('Avatar collapses empty name to single ?', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: Avatar(name: '   ')),
      ),
    );
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('Avatar renders CachedNetworkImage when photoUrl is set',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: Avatar(name: 'Ada', photoUrl: 'https://example.com/a.png'),
        ),
      ),
    );
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('Avatar featured tone draws a 3px gold border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: Avatar(name: 'Ada', tone: AvatarTone.featured),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('avatar-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, isA<Border>());
    final border = decoration.border! as Border;
    expect(border.top.width, 3);
    expect(border.top.color, const Color(0xFFFFC107));
  });

  testWidgets('AvatarCircle is an alias for Avatar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: AvatarCircle(name: 'Ada Lovelace')),
      ),
    );
    expect(find.text('AL'), findsOneWidget);
    expect(find.byType(Avatar), findsOneWidget);
  });
}

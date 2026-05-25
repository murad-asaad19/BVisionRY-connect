import 'package:connect_mobile/features/connections/presentation/connection_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

void main() {
  testWidgets('renders peer name + primary role', (tester) async {
    final widget = await wrapWithTheme(
      child: Scaffold(
        body: ConnectionRow(
          connection: buildConnection(name: 'Ava', primaryRole: 'investor'),
        ),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Ava'), findsOneWidget);
    expect(find.text('investor'), findsOneWidget);
  });

  testWidgets('omits primary role when null', (tester) async {
    final widget = await wrapWithTheme(
      child: Scaffold(
        body: ConnectionRow(
          connection: buildConnection(name: 'Ava', primaryRole: null),
        ),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('investor'), findsNothing);
  });

  testWidgets('renders connected-on caption with formatted date', (
    tester,
  ) async {
    final widget = await wrapWithTheme(
      child: Scaffold(
        body: ConnectionRow(
          connection: buildConnection(
            name: 'Ava',
            connectedAt: DateTime.utc(2026, 5, 20, 12),
          ),
        ),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.textContaining('Connected'), findsOneWidget);
  });
}

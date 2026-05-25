import 'package:connect_mobile/features/connections/data/connections_service.dart';
import 'package:connect_mobile/features/connections/domain/connection.dart';
import 'package:connect_mobile/features/connections/presentation/connections_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakeConnectionsService extends Mock implements ConnectionsService {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakeConnectionsService stub(List<Connection> rows) {
    final fake = _FakeConnectionsService();
    when(() => fake.listConnections()).thenAnswer((_) async => rows);
    return fake;
  }

  testWidgets('empty list renders EmptyState body copy', (tester) async {
    final widget = await wrapWithTheme(
      child: const ConnectionsScreen(),
      overrides: <Override>[
        connectionsServiceProvider
            .overrideWithValue(stub(const <Connection>[])),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.textContaining('No connections yet'), findsOneWidget);
  });

  testWidgets('renders rows with peer name', (tester) async {
    final widget = await wrapWithTheme(
      child: const ConnectionsScreen(),
      overrides: <Override>[
        connectionsServiceProvider.overrideWithValue(
          stub(<Connection>[buildConnection(name: 'Alice')]),
        ),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Alice'), findsOneWidget);
  });
}

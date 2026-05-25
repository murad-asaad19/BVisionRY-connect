import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/connections/data/connections_service.dart';
import 'package:connect_mobile/features/connections/domain/connection.dart';
import 'package:connect_mobile/features/connections/presentation/connections_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/intros_fixtures.dart';
import '../../../../helpers/pump.dart';

class _FakeConnectionsService extends Mock implements ConnectionsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakeConnectionsService stub(List<Connection> rows) {
    final fake = _FakeConnectionsService();
    when(() => fake.listConnections()).thenAnswer((_) async => rows);
    return fake;
  }

  testGoldens('ConnectionsScreen — populated list', (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          connectionsServiceProvider.overrideWithValue(
            stub(<Connection>[
              buildConnection(name: 'Alice', primaryRole: 'founder'),
              buildConnection(
                userId: 'peer-2',
                handle: 'bob',
                name: 'Bob',
                primaryRole: 'investor',
                conversationId: 'conv-2',
              ),
              buildConnection(
                userId: 'peer-3',
                handle: 'charlie',
                name: 'Charlie',
                primaryRole: 'builder',
                conversationId: 'conv-3',
              ),
            ]),
          ),
        ],
        child: const ConnectionsScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 600),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'connections_screen_populated');
  });

  testGoldens('ConnectionsScreen — empty state', (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          connectionsServiceProvider.overrideWithValue(
            stub(const <Connection>[]),
          ),
        ],
        child: const ConnectionsScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 600),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'connections_screen_empty');
  });
}

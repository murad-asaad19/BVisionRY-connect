import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/privacy/data/privacy_service.dart';
import 'package:connect_mobile/features/privacy/domain/blocked_user.dart';
import 'package:connect_mobile/features/privacy/presentation/blocked_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump.dart';

class _FakeService extends Mock implements PrivacyService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  testGoldens('BlockedUsersScreen — empty', (tester) async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer((_) async => const <BlockedUser>[]);
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          privacyServiceProvider.overrideWithValue(svc),
        ],
        child: const BlockedUsersScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 700),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'blocked_users_empty');
  });

  testGoldens('BlockedUsersScreen — populated', (tester) async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[
        BlockedUser(
          blockedId: 'b1',
          handle: 'alice',
          name: 'Alice Anderson',
          createdAt: DateTime.utc(2026, 5, 20),
        ),
        BlockedUser(
          blockedId: 'b2',
          handle: 'bob',
          name: 'Bob Bell',
          createdAt: DateTime.utc(2026, 5, 21),
        ),
        BlockedUser(
          blockedId: 'b3',
          handle: 'charlie_long_handle',
          name: 'Charlie Chen',
          createdAt: DateTime.utc(2026, 5, 22),
        ),
      ],
    );
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          privacyServiceProvider.overrideWithValue(svc),
        ],
        child: const BlockedUsersScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 700),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'blocked_users_populated');
  });
}

import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:connect_mobile/core/routing/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (_) async => null);
  });

  test('Routes.settingsBlocked resolves to a registered route', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final GoRouter router = container.read(appRouterProvider);
    final match = router.configuration.findMatch(
      Uri.parse(Routes.settingsBlocked),
    );
    expect(match.fullPath, Routes.settingsBlocked);
    expect(match.routes, isNotEmpty);
  });
}

import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('router builds without throwing', () {
    final ProviderContainer container = ProviderContainer();
    final GoRouter router = container.read(appRouterProvider);
    expect(router, isNotNull);
    container.dispose();
  });
}

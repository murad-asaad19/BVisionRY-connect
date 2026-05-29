import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/query_state.dart';
import 'package:connect_mobile/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump.dart';

/// [QueryState]'s default error block now resolves its copy via `context.t`,
/// so the widget must be hosted under a [ProviderScope] with the locale
/// loader primed. This wraps [child] accordingly without calling
/// `pumpAndSettle` (the loading skeleton shimmer never settles).
Future<Widget> _host(Widget child, LocaleLoader loader) async {
  return ProviderScope(
    overrides: <Override>[
      localeLoaderProvider.overrideWithValue(loader),
    ],
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('QueryState renders data builder when value is data',
      (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidget(
      await _host(
        QueryState<String>(
          value: const AsyncValue.data('hello'),
          data: (s) => Text(s),
        ),
        loader,
      ),
    );
    await tester.pump();
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('QueryState renders loading skeleton when value is loading',
      (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidget(
      await _host(
        QueryState<String>(
          value: const AsyncValue.loading(),
          data: (s) => Text(s),
        ),
        loader,
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('query-state-loading')), findsOneWidget);
    expect(find.byType(SkeletonListRow), findsNWidgets(3));
    // Unmount the animated subtree so the tickers can dispose.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('QueryState renders error UI + retry button when error',
      (tester) async {
    final loader = await primedLocaleLoader();
    var retried = false;
    await tester.pumpWidget(
      await _host(
        QueryState<String>(
          value: AsyncValue.error(Exception('boom'), StackTrace.current),
          data: (s) => Text(s),
          onRetry: () => retried = true,
        ),
        loader,
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('query-state-error')), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('QueryState honours custom loading slot', (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidget(
      await _host(
        QueryState<String>(
          value: const AsyncValue.loading(),
          data: (s) => Text(s),
          loading: const Text('custom-loading'),
        ),
        loader,
      ),
    );
    await tester.pump();
    expect(find.text('custom-loading'), findsOneWidget);
  });
}

import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/query_state.dart';
import 'package:connect_mobile/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QueryState renders data builder when value is data',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: QueryState<String>(
            value: const AsyncValue.data('hello'),
            data: (s) => Text(s),
          ),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('QueryState renders loading skeleton when value is loading',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: QueryState<String>(
            value: const AsyncValue.loading(),
            data: (s) => Text(s),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('query-state-loading')), findsOneWidget);
    expect(find.byType(SkeletonListRow), findsNWidgets(3));
    // Unmount the animated subtree so the tickers can dispose.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('QueryState renders error UI + retry button when error',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: QueryState<String>(
            value: AsyncValue.error(Exception('boom'), StackTrace.current),
            data: (s) => Text(s),
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('query-state-error')), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('QueryState honours custom loading slot', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: QueryState<String>(
            value: const AsyncValue.loading(),
            data: (s) => Text(s),
            loading: const Text('custom-loading'),
          ),
        ),
      ),
    );
    expect(find.text('custom-loading'), findsOneWidget);
  });
}

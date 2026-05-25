import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/query_state.dart';
import 'package:connect_mobile/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('QueryState states', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'data',
        QueryState<String>(
          value: const AsyncValue.data('Resolved row goes here.'),
          data: (s) => Text(s),
        ),
      )
      ..addScenario(
        'loading',
        QueryState<String>(
          value: const AsyncValue.loading(),
          // Render the static composite directly so `pumpAndSettle` works.
          loading: const Column(
            children: [
              SkeletonListRow(animate: false),
              SkeletonListRow(animate: false),
              SkeletonListRow(animate: false),
            ],
          ),
          data: (s) => Text(s),
        ),
      )
      ..addScenario(
        'error',
        QueryState<String>(
          value: AsyncValue.error(
            Exception('Network unreachable'),
            StackTrace.empty,
          ),
          data: (s) => Text(s),
          onRetry: () {},
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 1000),
    );
    await screenMatchesGolden(tester, 'query_state_variants');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);

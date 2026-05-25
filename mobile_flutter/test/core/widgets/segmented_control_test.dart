import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Tab { all, verified, mentors }

void main() {
  testWidgets('SegmentedControl renders all options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SegmentedControl<_Tab>(
            options: const [
              SegmentedOption(value: _Tab.all, label: 'All'),
              SegmentedOption(value: _Tab.verified, label: 'Verified'),
              SegmentedOption(value: _Tab.mentors, label: 'Mentors'),
            ],
            value: _Tab.all,
            onChange: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Mentors'), findsOneWidget);
  });

  testWidgets('SegmentedControl fires onChange with new value', (tester) async {
    _Tab? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SegmentedControl<_Tab>(
            options: const [
              SegmentedOption(value: _Tab.all, label: 'All'),
              SegmentedOption(value: _Tab.verified, label: 'Verified'),
            ],
            value: _Tab.all,
            onChange: (v) => captured = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Verified'));
    expect(captured, _Tab.verified);
  });

  testWidgets('SegmentedControl does not re-fire when active segment tapped',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SegmentedControl<_Tab>(
            options: const [
              SegmentedOption(value: _Tab.all, label: 'All'),
              SegmentedOption(value: _Tab.verified, label: 'Verified'),
            ],
            value: _Tab.all,
            onChange: (_) => calls += 1,
          ),
        ),
      ),
    );
    await tester.tap(find.text('All'));
    expect(calls, 0);
  });
}

import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppBottomSheet opened', (tester) async {
    await tester.pumpWidgetBuilder(
      Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: ctx,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sheet title',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F3460),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Body content lives here and stretches to fit the contents.',
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 640),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'app_bottom_sheet_opened');
  });
}

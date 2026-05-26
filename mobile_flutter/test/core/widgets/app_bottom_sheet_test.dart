import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showAppBottomSheet renders the child and resolves on pop',
      (tester) async {
    late Future<String?> result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (ctx) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  result = showAppBottomSheet<String>(
                    context: ctx,
                    child: Builder(
                      builder: (sheetCtx) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Sheet body'),
                            TextButton(
                              onPressed: () => Navigator.of(sheetCtx).pop('ok'),
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(await result, 'ok');
  });

  testWidgets('AppBottomSheet renders the drag handle bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (ctx) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showAppBottomSheet<void>(
                  context: ctx,
                  child: const SizedBox(height: 80, child: Text('hi')),
                ),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('app-bottom-sheet-handle')), findsOneWidget,);
  });
}

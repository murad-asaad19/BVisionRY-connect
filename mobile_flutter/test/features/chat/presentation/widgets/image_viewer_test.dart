import 'package:connect_mobile/features/chat/presentation/widgets/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders fullscreen dialog with close button', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: ImageViewer(url: 'https://example.com/photo.jpg'),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('image-viewer-close')), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('close button pops the navigator', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ImageViewer.show(
                  ctx,
                  url: 'https://example.com/photo.jpg',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewer), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('image-viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewer), findsNothing);
  });
}

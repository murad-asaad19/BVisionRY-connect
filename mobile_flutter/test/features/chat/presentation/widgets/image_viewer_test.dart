import 'package:connect_mobile/features/chat/presentation/widgets/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders fullscreen dialog with close button', (tester) async {
    final widget = await wrapWithTheme(
      child: const Scaffold(
        body: ImageViewer(url: 'https://example.com/photo.jpg'),
      ),
    );
    // The CachedNetworkImage placeholder is a CircularProgressIndicator
    // that animates forever in a test (no real network). Use `pump`
    // instead of `pumpAndSettle` to avoid hanging.
    await tester.pumpWidget(widget);
    await tester.pump();
    expect(find.byKey(const ValueKey('image-viewer-close')), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('close button pops the navigator', (tester) async {
    final widget = await wrapWithTheme(
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
    );
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.tap(find.text('open'));
    // pump the open transition manually; the spinner blocks pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(ImageViewer), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('image-viewer-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(ImageViewer), findsNothing);
  });
}

import 'package:connect_mobile/core/analytics/sentry_error_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders child when no error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SentryErrorBoundary(
          child: Scaffold(body: Text('child-ok')),
        ),
      ),
    );
    expect(find.text('child-ok'), findsOneWidget);
  });

  testWidgets('shows fallback when child throws during build',
      (WidgetTester tester) async {
    Object? captured;
    StackTrace? capturedStack;

    await tester.pumpWidget(
      MaterialApp(
        home: SentryErrorBoundary(
          onError: (Object e, StackTrace s) {
            captured = e;
            capturedStack = s;
          },
          fallbackBuilder: (BuildContext ctx, Object error) =>
              const Scaffold(body: Text('boundary-fallback')),
          child: Builder(
            builder: (_) => throw StateError('boom'),
          ),
        ),
      ),
    );

    expect(find.text('boundary-fallback'), findsOneWidget);
    expect(captured, isA<StateError>());
    expect(capturedStack, isNotNull);
  });

  testWidgets('default fallback renders a generic message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SentryErrorBoundary(
          child: Builder(builder: (_) => throw StateError('boom')),
        ),
      ),
    );
    // Default fallback uses a Material widget for the fallback shell —
    // verify we get a Material rendered.
    expect(find.byType(Material), findsWidgets);
  });

  testWidgets('captures error via onError sink even when Sentry is disabled',
      (WidgetTester tester) async {
    Object? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: SentryErrorBoundary(
          onError: (Object e, StackTrace _) => captured = e,
          child: Builder(
            builder: (_) => throw const FormatException('bad'),
          ),
        ),
      ),
    );
    expect(captured, isA<FormatException>());
  });
}

import 'package:connect_mobile/features/push/domain/notification_channel.dart';
import 'package:connect_mobile/features/push/domain/notification_kind.dart';
import 'package:connect_mobile/features/settings/presentation/widgets/notification_matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  Future<void> render(WidgetTester tester, NotificationMatrix matrix) async {
    final Widget shell = await wrapWithTheme(
      child: Scaffold(body: SingleChildScrollView(child: matrix)),
    );
    await pumpWithI18n(tester, shell);
  }

  testWidgets('NotificationMatrix renders 10 rows × 3 channels (30 switches)',
      (WidgetTester tester) async {
    await render(
      tester,
      NotificationMatrix(
        prefs: const <String, bool>{},
        onChanged: (_, __, ___) {},
      ),
    );
    expect(find.byType(Switch), findsNWidgets(30));
  });

  testWidgets('Switch defaults to ON when no row present (default-open §17.13)',
      (WidgetTester tester) async {
    await render(
      tester,
      NotificationMatrix(
        prefs: const <String, bool>{},
        onChanged: (_, __, ___) {},
      ),
    );
    final Switch first = tester.widget<Switch>(find.byType(Switch).first);
    expect(first.value, isTrue);
  });

  testWidgets('Persisted false entry renders the switch OFF',
      (WidgetTester tester) async {
    await render(
      tester,
      NotificationMatrix(
        prefs: const <String, bool>{'intro_received:push': false},
        onChanged: (_, __, ___) {},
      ),
    );
    final Switch sw = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('matrix.switch.intro_received.push')),
        matching: find.byType(Switch),
      ),
    );
    expect(sw.value, isFalse);
  });

  testWidgets('Tapping a switch fires onChanged with (kind, channel, enabled)',
      (WidgetTester tester) async {
    NotificationKind? capturedKind;
    NotificationChannel? capturedChannel;
    bool? capturedEnabled;
    await render(
      tester,
      NotificationMatrix(
        prefs: const <String, bool>{},
        onChanged: (NotificationKind k, NotificationChannel c, bool e) {
          capturedKind = k;
          capturedChannel = c;
          capturedEnabled = e;
        },
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('matrix.switch.message_received.push')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    expect(capturedKind, NotificationKind.messageReceived);
    expect(capturedChannel, NotificationChannel.push);
    expect(capturedEnabled, isFalse);
  });

  testWidgets('No-emitter chips render for the 4 §17.4 kinds',
      (WidgetTester tester) async {
    await render(
      tester,
      NotificationMatrix(
        prefs: const <String, bool>{},
        onChanged: (_, __, ___) {},
      ),
    );
    expect(
      find.byKey(const Key('matrix.noEmitterChip.intro_accepted')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('matrix.noEmitterChip.meeting_reminder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('matrix.noEmitterChip.daily_matches_ready')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('matrix.noEmitterChip.goal_staleness')),
      findsOneWidget,
    );
  });

  testWidgets('Footer surfaces the email-unavailable note (§17.1)',
      (WidgetTester tester) async {
    await render(
      tester,
      NotificationMatrix(
        prefs: const <String, bool>{},
        onChanged: (_, __, ___) {},
      ),
    );
    expect(
      find.byKey(const Key('matrix.emailUnavailableNote')),
      findsOneWidget,
    );
  });
}

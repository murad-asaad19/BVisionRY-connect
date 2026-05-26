import 'package:connect_mobile/features/chat/domain/message.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/message_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

Message _ownText({
  String? body,
  DateTime? createdAt,
  bool deleted = false,
}) {
  return Message(
    id: 'm1',
    conversationId: 'c1',
    senderId: 'self',
    kind: MessageKind.text,
    createdAt: createdAt ?? DateTime.now().toUtc(),
    body: body ?? 'hello',
    deletedAt: deleted ? DateTime.now().toUtc() : null,
  );
}

void main() {
  testWidgets('shows Reply + Edit + Copy + Delete + Report for own text msg', (
    tester,
  ) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          body: MessageActionsSheet(
            message: _ownText(),
            currentUserId: 'self',
          ),
        ),
      ),
    );
    expect(find.textContaining('Reply'), findsOneWidget);
    expect(find.textContaining('Edit'), findsOneWidget);
    expect(find.textContaining('Copy'), findsOneWidget);
    expect(find.textContaining('Delete'), findsOneWidget);
    expect(find.textContaining('Report'), findsOneWidget);
  });

  testWidgets(
    'hides Edit when older than 15min and Delete when not the sender',
    (tester) async {
      final old = _ownText(
        createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      await pumpWithI18n(
        tester,
        await wrapWithTheme(
          child: Scaffold(
            body: MessageActionsSheet(
              message: old.copyWith(senderId: 'someone-else'),
              currentUserId: 'self',
            ),
          ),
        ),
      );
      expect(find.textContaining('Edit'), findsNothing);
      expect(find.textContaining('Delete'), findsNothing);
      // Reply / Report still visible.
      expect(find.textContaining('Reply'), findsOneWidget);
      expect(find.textContaining('Report'), findsOneWidget);
    },
  );

  testWidgets('hides Copy when message has no body', (tester) async {
    final image = Message(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'self',
      kind: MessageKind.image,
      createdAt: DateTime.now().toUtc(),
      mediaPath: 'c1/m1/photo.jpg',
    );
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          body: MessageActionsSheet(
            message: image,
            currentUserId: 'self',
          ),
        ),
      ),
    );
    expect(find.textContaining('Copy'), findsNothing);
  });
}

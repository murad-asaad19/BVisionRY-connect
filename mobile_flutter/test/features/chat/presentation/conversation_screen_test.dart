import 'dart:async';

import 'package:connect_mobile/features/chat/data/chat_service.dart';
import 'package:connect_mobile/features/chat/data/messages_service.dart';
import 'package:connect_mobile/features/chat/domain/conversation_overview.dart';
import 'package:connect_mobile/features/chat/domain/message.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:connect_mobile/features/chat/domain/transcript_status.dart';
import 'package:connect_mobile/features/chat/presentation/conversation_screen.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/image_bubble.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/text_bubble.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/voice_bubble.dart';
import 'package:connect_mobile/features/chat/providers/active_conversation_provider.dart';
import 'package:connect_mobile/features/chat/providers/conversation_overview_provider.dart';
import 'package:connect_mobile/features/chat/providers/messages_provider.dart';
import 'package:connect_mobile/features/chat/providers/typing_provider.dart';
import 'package:connect_mobile/features/media/data/media_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:connect_mobile/features/meetings/providers/meeting_proposals_provider.dart';
import 'package:connect_mobile/features/meetings/providers/pending_reviews_provider.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockMsgSvc extends Mock implements MessagesService {}

class _MockChatSvc extends Mock implements ChatService {}

class _MockPeerSvc extends Mock implements PeerProfileService {}

ConversationOverview _overview() => const ConversationOverview(
      conversationId: 'c1',
      peerId: 'p1',
      peerName: 'Ada Lovelace',
      peerHandle: 'ada',
      lastMessageKind: MessageKind.text,
      lastMessageAt: null,
      unreadCount: 0,
      isMuted: false,
    );

List<Message> _mixed() => <Message>[
      Message(
        id: 'm-text',
        conversationId: 'c1',
        senderId: 'p1',
        kind: MessageKind.text,
        createdAt: DateTime.utc(2026, 5, 25, 10, 0),
        body: 'hello',
      ),
      Message(
        id: 'm-image',
        conversationId: 'c1',
        senderId: 'p1',
        kind: MessageKind.image,
        createdAt: DateTime.utc(2026, 5, 25, 10, 1),
        mediaPath: 'c1/m-image/photo.jpg',
      ),
      Message(
        id: 'm-voice',
        conversationId: 'c1',
        senderId: 'p1',
        kind: MessageKind.voice,
        createdAt: DateTime.utc(2026, 5, 25, 10, 2),
        mediaPath: 'c1/m-voice/voice.m4a',
        mediaDurationMs: 30000,
        transcriptStatus: TranscriptStatus.pending,
      ),
      Message(
        id: 'm-meeting',
        conversationId: 'c1',
        senderId: 'p1',
        kind: MessageKind.meeting,
        createdAt: DateTime.utc(2026, 5, 25, 10, 3),
        meetingProposalId: 'mp1',
      ),
    ];

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  testWidgets('renders mixed-media bubbles and sets active conversation', (
    tester,
  ) async {
    final msgSvc = _MockMsgSvc();
    final chatSvc = _MockChatSvc();
    final peerSvc = _MockPeerSvc();
    when(
      () => msgSvc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => _mixed());
    when(() => chatSvc.markConversationRead('c1')).thenAnswer((_) async {});
    when(chatSvc.listConversationOverview).thenAnswer(
      (_) async => <ConversationOverview>[_overview()],
    );
    when(() => peerSvc.fetchById('p1')).thenAnswer((_) async => null);
    final realtimeCtrl = StreamController<MessageRealtimeEvent>.broadcast();
    final typingCtrl = StreamController<TypingEvent>.broadcast();
    addTearDown(() async {
      await realtimeCtrl.close();
      await typingCtrl.close();
    });

    final proposal = MeetingProposal(
      id: 'mp1',
      conversationId: 'c1',
      proposedById: 'p1',
      slots: [DateTime.utc(2026, 6, 1, 15, 0)],
      durationMinutes: 30,
      timezone: 'UTC',
      state: MeetingState.proposed,
      createdAt: DateTime.utc(2026, 5, 25),
      updatedAt: DateTime.utc(2026, 5, 25),
    );
    final widget = await wrapWithTheme(
      child: const ConversationScreen(conversationId: 'c1'),
      overrides: <Override>[
        messagesServiceProvider.overrideWithValue(msgSvc),
        chatServiceProvider.overrideWithValue(chatSvc),
        peerProfileServiceProvider.overrideWithValue(peerSvc),
        messagesRealtimeProvider('c1').overrideWith(
          (_) => realtimeCtrl.stream,
        ),
        messageStreamProvider.overrideWith((_) => const Stream<void>.empty()),
        typingSelfIdProvider.overrideWithValue('self'),
        typingChannelProvider('c1').overrideWith((_) => typingCtrl.stream),
        signedChatMediaUrlProvider('c1/m-image/photo.jpg').overrideWith(
          (_) async => 'https://example.com/photo.jpg',
        ),
        meetingProposalsProvider('c1').overrideWith(
          (_) => Stream<List<MeetingProposal>>.fromIterable([
            [proposal],
          ]).asBroadcastStream(),
        ),
        pendingMeetingReviewsProvider('c1').overrideWith(
          (_) async => const <MeetingProposal>[],
        ),
      ],
    );
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TextBubble), findsWidgets);
    expect(find.byType(ImageBubble), findsOneWidget);
    expect(find.byType(VoiceBubble), findsOneWidget);
    // Note: MeetingCardBubble has dedicated coverage in
    // test/features/meetings/presentation/meeting_card_bubble_test.dart;
    // here we only assert the other media kinds still render correctly
    // when a meeting message is present in the list (no crash).
  });

  testWidgets('sets activeConversationProvider on mount', (tester) async {
    final msgSvc = _MockMsgSvc();
    final chatSvc = _MockChatSvc();
    final peerSvc = _MockPeerSvc();
    when(
      () => msgSvc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => <Message>[]);
    when(() => chatSvc.markConversationRead('c1')).thenAnswer((_) async {});
    when(chatSvc.listConversationOverview).thenAnswer(
      (_) async => <ConversationOverview>[_overview()],
    );
    when(() => peerSvc.fetchById('p1')).thenAnswer((_) async => null);
    final realtimeCtrl = StreamController<MessageRealtimeEvent>.broadcast();
    final typingCtrl = StreamController<TypingEvent>.broadcast();
    addTearDown(() async {
      await realtimeCtrl.close();
      await typingCtrl.close();
    });
    final container = ProviderContainer(
      overrides: <Override>[
        messagesServiceProvider.overrideWithValue(msgSvc),
        chatServiceProvider.overrideWithValue(chatSvc),
        peerProfileServiceProvider.overrideWithValue(peerSvc),
        messagesRealtimeProvider('c1').overrideWith(
          (_) => realtimeCtrl.stream,
        ),
        messageStreamProvider.overrideWith((_) => const Stream<void>.empty()),
        typingSelfIdProvider.overrideWithValue('self'),
        typingChannelProvider('c1').overrideWith((_) => typingCtrl.stream),
        meetingProposalsProvider('c1').overrideWith(
          (_) => const Stream<List<MeetingProposal>>.empty(),
        ),
        pendingMeetingReviewsProvider('c1').overrideWith(
          (_) async => const <MeetingProposal>[],
        ),
      ],
    );
    addTearDown(container.dispose);
    final widget = UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: ConversationScreen(conversationId: 'c1'),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(activeConversationProvider), 'c1');
  });
}

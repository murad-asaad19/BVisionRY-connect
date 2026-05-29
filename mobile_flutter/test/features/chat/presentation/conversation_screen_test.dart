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
import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/supabase/supabase_client.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

/// [ConversationScreen] now drives navigation through GoRouter
/// (`context.canPop()` / `context.go(Routes.inbox)`), so a bare
/// `MaterialApp` is no longer enough — it must be hosted inside a router.
/// This wraps the screen in a minimal GoRouter (screen at `/`, plus an
/// `/inbox` fallback target) with the i18n loader primed and the supplied
/// provider overrides.
Future<Widget> wrapWithRouter({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) async {
  final LocaleLoader loader = await primedLocaleLoader();
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => child),
      GoRoute(
        path: '/inbox',
        builder: (_, __) => const Scaffold(body: Text('inbox')),
      ),
    ],
  );
  return ProviderScope(
    overrides: <Override>[
      localeLoaderProvider.overrideWithValue(loader),
      ...overrides,
    ],
    child: MaterialApp.router(
      theme: buildAppTheme(Brightness.light),
      routerConfig: router,
    ),
  );
}

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
    final widget = await wrapWithRouter(
      child: const ConversationScreen(conversationId: 'c1'),
      overrides: <Override>[
        supabaseInitProvider.overrideWith((_) async {}),
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
    final LocaleLoader loader = await primedLocaleLoader();
    final container = ProviderContainer(
      overrides: <Override>[
        localeLoaderProvider.overrideWithValue(loader),
        supabaseInitProvider.overrideWith((_) async {}),
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
    // The screen drives navigation through GoRouter, so host it in a minimal
    // router rather than a bare MaterialApp (otherwise context.canPop() throws
    // "No GoRouter found in context").
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, __) => const ConversationScreen(conversationId: 'c1'),
        ),
        GoRoute(
          path: '/inbox',
          builder: (_, __) => const Scaffold(body: Text('inbox')),
        ),
      ],
    );
    final widget = UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildAppTheme(Brightness.light),
        routerConfig: router,
      ),
    );
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(activeConversationProvider), 'c1');
  });
}

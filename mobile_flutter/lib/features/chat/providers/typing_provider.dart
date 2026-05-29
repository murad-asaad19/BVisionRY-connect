import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

/// One typing-ping received from the other participant.
@immutable
class TypingEvent {
  const TypingEvent(this.userId, this.timestamp);
  final String userId;
  final DateTime timestamp;
}

/// Per-conversation broadcast channel that emits a [TypingEvent] every
/// time the OTHER participant sends a `typing` broadcast.
///
/// Production: opens `supabase.channel('typing:$convId')` with an
/// `onBroadcast(event:'typing')` handler. Tests override this provider
/// with a controlled stream.
///
/// AutoDispose so the broadcast channel is torn down when the listening
/// [typingProvider] (also autoDispose) is released — without it, every
/// conversation visited would keep its Supabase broadcast subscription
/// open for the rest of the session.
final AutoDisposeStreamProviderFamily<TypingEvent, String>
    typingChannelProvider =
    StreamProvider.autoDispose.family<TypingEvent, String>((ref, convId) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<TypingEvent>.broadcast();
  final ch = client.channel('typing:$convId');
  ch
      .onBroadcast(
        event: 'typing',
        callback: (payload) {
          final userId = payload['user_id'] as String?;
          if (userId == null) return;
          controller.add(TypingEvent(userId, DateTime.now().toUtc()));
        },
      )
      .subscribe();
  ref.onDispose(() async {
    await client.removeChannel(ch);
    await controller.close();
  });
  return controller.stream;
});

/// Resolves the current authenticated user id so [typingProvider] can
/// filter out the caller's own pings without re-reading the Supabase
/// client (which makes the provider easier to fake in tests).
final Provider<String?> typingSelfIdProvider = Provider<String?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser?.id;
});

/// The set of user ids that are currently typing (other than self). Each
/// id auto-clears 2 seconds after the last received ping for that user.
///
/// AutoDispose so leaving a thread releases the channel.
final AutoDisposeStreamProviderFamily<Set<String>, String> typingProvider =
    StreamProvider.autoDispose.family<Set<String>, String>((ref, convId) {
  final selfId = ref.watch(typingSelfIdProvider);
  final controller = StreamController<Set<String>>.broadcast();
  final active = <String, Timer>{};
  final current = <String>{};

  // Seed with an empty set so listeners see "nobody typing" immediately.
  Future.microtask(() => controller.add(<String>{}));

  ref.listen<AsyncValue<TypingEvent>>(typingChannelProvider(convId), (
    _,
    next,
  ) {
    next.whenData((ev) {
      if (ev.userId == selfId) return;
      current.add(ev.userId);
      controller.add(Set<String>.from(current));
      active[ev.userId]?.cancel();
      active[ev.userId] = Timer(const Duration(seconds: 2), () {
        current.remove(ev.userId);
        controller.add(Set<String>.from(current));
      });
    });
  });

  ref.onDispose(() {
    for (final t in active.values) {
      t.cancel();
    }
    controller.close();
  });
  return controller.stream;
});

/// Debounced broadcaster — call [ping] on every keystroke; pings are
/// dropped while a 1.5 s cooldown is active so the channel never sees
/// more than one ping per 1.5 s per user.
class TypingBroadcaster {
  TypingBroadcaster(this._client);
  final SupabaseClient _client;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  /// Optional clock override for tests.
  @visibleForTesting
  DateTime Function() now = () => DateTime.now();

  Future<void> ping(String convId) async {
    final n = now();
    if (n.difference(_lastSent) < const Duration(milliseconds: 1500)) return;
    _lastSent = n;
    final selfId = _client.auth.currentUser?.id;
    if (selfId == null) return;
    final ch = _client.channel('typing:$convId');
    await ch.sendBroadcastMessage(
      event: 'typing',
      payload: <String, dynamic>{'user_id': selfId},
    );
  }

  @visibleForTesting
  void resetCooldown() {
    _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

final Provider<TypingBroadcaster> typingBroadcasterProvider =
    Provider<TypingBroadcaster>((ref) {
  return TypingBroadcaster(ref.watch(supabaseClientProvider));
});

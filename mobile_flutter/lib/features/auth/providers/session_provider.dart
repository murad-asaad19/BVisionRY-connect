import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart' show AuthGateway;
import 'auth_service_provider.dart';

/// Streams the current Supabase [Session]?, seeded with [AuthGateway.currentSession]
/// so first-frame consumers don't see [AsyncLoading] when a session is already
/// restored on cold start. Forwards every subsequent transition from
/// `auth.onAuthStateChange()`.
///
/// Implemented with a [StreamController] (rather than `async*`) so we attach
/// the upstream subscription synchronously before yielding the seed — this
/// avoids losing the very first state change on broadcast streams.
final StreamProvider<Session?> sessionProvider = StreamProvider<Session?>((
  Ref<AsyncValue<Session?>> ref,
) {
  final AuthGateway gateway = ref.watch(authGatewayProvider);
  final StreamController<Session?> controller = StreamController<Session?>();
  final StreamSubscription<AuthState> sub = gateway.onAuthStateChange().listen(
    (AuthState state) => controller.add(state.session),
    onError: controller.addError,
  );
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  // Seed with the current synchronous session so first-frame consumers see
  // the right value without an [AsyncLoading] flash.
  controller.add(gateway.currentSession);
  return controller.stream;
});

/// Synchronous accessor for the latest [Session]?. Does not itself subscribe
/// to the stream — composes via [Ref.watch] of [sessionProvider].
final Provider<Session?> currentSessionProvider = Provider<Session?>((
  Ref<Session?> ref,
) {
  return ref.watch(sessionProvider).valueOrNull;
});

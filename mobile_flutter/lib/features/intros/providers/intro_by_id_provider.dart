import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/intro.dart';
import 'intros_providers.dart';

/// Resolves a single [Intro] by id.
///
/// Tries the already-cached received / sent lists first so opening the
/// detail screen from the Inbox is synchronous; falls back to throwing a
/// [NotFoundException] otherwise so the detail screen surfaces a localized
/// "not found" state (via `QueryState`) with a recovery path instead of a
/// raw `StateError`. A live fetch-by-id helper isn't required for Chunk A —
/// every reachable detail surface comes from a list already in memory.
final FutureProviderFamily<Intro, String> introByIdProvider =
    FutureProvider.family<Intro, String>((ref, String id) async {
  final received = await ref.watch(receivedIntrosProvider.future);
  for (final i in received) {
    if (i.id == id) return i;
  }
  final sent = await ref.watch(sentIntrosProvider.future);
  for (final i in sent) {
    if (i.id == id) return i;
  }
  throw NotFoundException();
});

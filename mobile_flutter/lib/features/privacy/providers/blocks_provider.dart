import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/privacy_service.dart';
import '../domain/blocked_user.dart';

/// All users the caller has blocked, newest-first. Drives the
/// `/settings/blocked-users` list and the [isBlockedProvider] cache.
///
/// Invalidate this provider after `block_user` / `unblock_user` succeeds —
/// the BlockButton and BlockedUsersScreen do exactly that.
final FutureProvider<List<BlockedUser>> blocksProvider =
    FutureProvider<List<BlockedUser>>((ref) async {
  return ref.watch(privacyServiceProvider).listBlockedUsers();
});

/// Cheap synchronous "is this user already blocked?" lookup, derived from
/// [blocksProvider]. Returns `false` while the list is still loading so
/// downstream UI (BlockButton, discovery rows) defaults to the "Block"
/// label rather than flashing "Unblock" momentarily on cold start.
final ProviderFamily<bool, String> isBlockedProvider =
    Provider.family<bool, String>((ref, String userId) {
  final List<BlockedUser> list = ref.watch(blocksProvider).maybeWhen(
        data: (List<BlockedUser> xs) => xs,
        orElse: () => const <BlockedUser>[],
      );
  return list.any((BlockedUser u) => u.blockedId == userId);
});

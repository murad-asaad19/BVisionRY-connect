import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id of the conversation the user is currently viewing, or `null` when
/// they're not inside a thread.
///
/// `ConversationScreen` sets this on mount and clears it on dispose so
/// Phase 12 push handlers can suppress in-thread toasts ("Don't show a
/// banner for a message we're already displaying").
final StateProvider<String?> activeConversationProvider =
    StateProvider<String?>(
  (ref) => null,
);

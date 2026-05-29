import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/providers/conversation_overview_provider.dart';
import '../../chat/providers/unread_counts_provider.dart';
import '../../connections/providers/connections_provider.dart';
import '../../intros/providers/intros_providers.dart';
import '../../opportunities/providers/my_opportunities_provider.dart';
import '../../opportunities/providers/opportunities_feed_provider.dart';
import '../../privacy/providers/blocks_provider.dart';
import 'profile_provider.dart';

/// Catalog of every Riverpod provider whose cache is keyed to the current
/// signed-in user. Exposed as a constant list so the same set is dropped on
/// sign-out AND on app-lifecycle resume.
///
/// Add NEW authed providers here when introducing them. Pure provider
/// families that auto-dispose still benefit because we drop any foreground
/// subscription a screen happens to be holding.
final List<ProviderOrFamily> kAuthedProviders = <ProviderOrFamily>[
  receivedIntrosProvider,
  sentIntrosProvider,
  connectionsProvider,
  blocksProvider,
  conversationOverviewProvider,
  unreadCountsProvider,
  myOpportunitiesProvider,
  opportunitiesFeedProvider,
  profileProvider,
];

/// Invalidates every authed provider via a [Ref]. Used by `signOut` to
/// drop the previous session's cache so the next sign-in renders fresh
/// data instead of the prior user's snapshot.
void invalidateAuthedProviders(Ref ref) {
  for (final p in kAuthedProviders) {
    ref.invalidate(p);
  }
}

/// Invalidates every authed provider via a [WidgetRef]. The lifecycle
/// observer in `app.dart` lives in a widget so it holds a [WidgetRef]; the
/// underlying behaviour is identical to [invalidateAuthedProviders].
void invalidateAuthedProvidersWithWidgetRef(WidgetRef ref) {
  for (final p in kAuthedProviders) {
    ref.invalidate(p);
  }
}

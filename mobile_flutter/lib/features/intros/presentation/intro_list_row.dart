import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/domain/profile.dart';
import '../../profile/providers/peer_profile_provider.dart';
import '../domain/intro.dart';
import 'intro_state_badge.dart';

/// One row in the Received / Sent lists.
///
/// Layout: 36px avatar + a column with peer name + truncated note snippet,
/// and a trailing [IntroStateBadge]. Tapping the row pushes the detail
/// route.
///
/// The note and state badge come straight off the [Intro] and render
/// immediately. Only the peer identity (avatar + name) is resolved through
/// [peerProfileProvider] keyed off the relevant side of the intro
/// (recipient_id when the viewer is the sender, sender_id otherwise). That
/// secondary lookup is scoped to just the avatar + name so the whole row no
/// longer flashes a full-row skeleton (the old N+1 behaviour). On peer-load
/// failure we fall back to any [Intro]-embedded profile, then to a neutral
/// placeholder name — never the raw UUID.
class IntroListRow extends ConsumerWidget {
  const IntroListRow({
    super.key,
    required this.intro,
    required this.viewerIsRecipient,
  });

  final Intro intro;

  /// `true` when the viewing user received this intro — drives whether we
  /// resolve the sender (received view) or the recipient (sent view).
  final bool viewerIsRecipient;

  static const int _snippetMaxChars = 80;

  String get _peerId => viewerIsRecipient ? intro.senderId : intro.recipientId;

  /// Profile embedded on the intro row itself (if the list query joined it),
  /// used as a fallback before resorting to a neutral placeholder.
  Profile? get _embeddedPeer =>
      viewerIsRecipient ? intro.sender : intro.recipient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final snippet = intro.note.length > _snippetMaxChars
        ? '${intro.note.substring(0, _snippetMaxChars).trimRight()}…'
        : intro.note;

    // Resolve the peer without blocking the row: the avatar + name area
    // shows its own skeleton while the lookup is in-flight; the note +
    // badge below stay rendered the whole time.
    final AsyncValue<Profile?> peerAsync =
        ref.watch(peerProfileProvider(_peerId));
    final Profile? peer = peerAsync.valueOrNull ?? _embeddedPeer;
    final bool loadingPeer = peerAsync.isLoading && peer == null;
    final String peerName = peer?.name ?? context.t('intros.row.unknownPeer');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(Routes.intro(intro.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loadingPeer)
                const Skeleton(width: 36, height: 36, rounded: 18)
              else
                Avatar(
                  name: peerName,
                  photoUrl: peer?.photoUrl,
                  size: 36,
                  semanticLabel: peerName,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: loadingPeer
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Skeleton(width: 120, height: 12),
                                )
                              : Text(
                                  peerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: typo.displaySm
                                      .copyWith(color: colors.navy),
                                ),
                        ),
                        const SizedBox(width: 8),
                        IntroStateBadge(
                          state: intro.state,
                          fromSender: !viewerIsRecipient,
                          connectedAt: intro.createdAt,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typo.bodyMd.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

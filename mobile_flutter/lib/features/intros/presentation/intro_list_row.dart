import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
/// Layout: 44px [Avatar] + a column with peer name + truncated note
/// snippet, and a trailing [IntroStateBadge]. Tapping the row pushes the
/// detail route.
///
/// The peer's identity is resolved through [peerProfileProvider] keyed off
/// the relevant side of the intro (recipient_id when the viewer is the
/// sender, sender_id otherwise). While the lookup is in-flight a skeleton
/// row keeps the layout stable; on error we fall back to rendering the
/// user id so the row is still tappable.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Profile?> async = ref.watch(peerProfileProvider(_peerId));
    return async.when(
      loading: () => const SkeletonListRow(),
      error: (_, __) => _RowBody(
        intro: intro,
        peerName: _peerId,
        peerHandle: _peerId,
        peerPhotoUrl: null,
        snippetMaxChars: _snippetMaxChars,
      ),
      data: (Profile? profile) => _RowBody(
        intro: intro,
        peerName: profile?.name ?? _peerId,
        peerHandle: profile?.handle ?? _peerId,
        peerPhotoUrl: profile?.photoUrl,
        snippetMaxChars: _snippetMaxChars,
      ),
    );
  }
}

class _RowBody extends StatelessWidget {
  const _RowBody({
    required this.intro,
    required this.peerName,
    required this.peerHandle,
    required this.peerPhotoUrl,
    required this.snippetMaxChars,
  });

  final Intro intro;
  final String peerName;
  final String peerHandle;
  final String? peerPhotoUrl;
  final int snippetMaxChars;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final snippet = intro.note.length > snippetMaxChars
        ? '${intro.note.substring(0, snippetMaxChars).trimRight()}…'
        : intro.note;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(Routes.intro(intro.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(name: peerName, photoUrl: peerPhotoUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                typo.displaySm.copyWith(color: colors.navy),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IntroStateBadge(state: intro.state),
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

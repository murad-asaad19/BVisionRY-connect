import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/user_card.dart';
import '../../auth/providers/profile_provider.dart';
import '../../intros/presentation/intro_or_chat_button.dart';
import '../../intros/presentation/send_intro_sheet.dart';
import '../domain/daily_match.dart';
import '../domain/match_reason.dart';
import '../domain/role_label.dart';
import '../domain/specific_match_reason.dart';
import 'match_reason_chip.dart';
import 'widgets/discovery_status_pill.dart';

/// Discovery card surfaced on the Home screen for each daily pick.
///
/// Wraps the foundation [UserCard] and passes the [MatchReasonChip] into
/// its `reason` slot. When the viewer profile is available, the chip text
/// is composed with [composeSpecificMatchReason] for a per-pick specific
/// line (gallery §9 "highest-specificity heuristic per pick"); otherwise
/// the categorical label is shown.
///
/// Below the card sits a "Request intro" affordance that opens the
/// [showSendIntroSheet] composer directly — so a pick can be actioned
/// without first navigating into the public profile.
///
/// View-tracking: when [onSeen] is provided AND the underlying match has
/// not yet been seen (`match.viewedAt == null`), wraps the card in a
/// [VisibilityDetector] that fires `onSeen` exactly once at ≥ 50% visible.
class MatchCard extends ConsumerStatefulWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.featured = false,
    this.onSeen,
    this.entranceIndex = 0,
  });

  final DailyMatch match;
  final VoidCallback onTap;
  final bool featured;
  final VoidCallback? onSeen;

  /// Position in the daily-match list. Drives a one-shot, staggered entrance
  /// (each card fades + lifts in slightly after the one above it) so the feed
  /// assembles with a gentle cascade rather than popping in all at once.
  final int entranceIndex;

  @override
  ConsumerState<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<MatchCard> {
  bool _seenDispatched = false;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final reason = MatchReason.fromServer(widget.match.matchReason);
    final profile = widget.match.profile;
    final viewer = ref.watch(profileProvider).asData?.value;
    final specific = viewer == null
        ? null
        : composeSpecificMatchReason(viewer: viewer, match: profile);
    final role = profile.primaryRole;
    // The featured #1 pick carries the gold match-reason chip (gallery C1
    // .reason). Non-featured browse rows keep their reason too — but as the
    // muted goldPale chip — whenever a profile-specific reason was derivable,
    // so a pick never silently loses its "why". When no specific reason is
    // available they fall back to the activity / badge status pill (gallery
    // C1 lines 1454-1468), collapsing the slot when neither applies.
    final Widget? reasonSlot = widget.featured
        ? MatchReasonChip(
            reason: reason,
            specificText: specific,
            featured: true,
          )
        : (specific != null
            ? MatchReasonChip(
                reason: reason,
                specificText: specific,
                featured: false,
              )
            : (DiscoveryStatusPill.hasStatus(profile)
                ? DiscoveryStatusPill(profile: profile)
                : null));
    final card = UserCard(
      name: profile.name ?? '@${profile.handle}',
      primaryRole:
          (role == null || role.isEmpty) ? '' : roleLabel(context, role),
      photoUrl: profile.photoUrl,
      headline: profile.headline,
      city: profile.city,
      country: profile.country,
      featured: widget.featured,
      verified: profile.verified,
      reason: reasonSlot,
      onTap: () {
        Analytics.log(
          AppEvent.matchCardOpened,
          <String, Object>{'featured': widget.featured},
        );
        widget.onTap();
      },
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        card,
        Padding(
          padding: EdgeInsets.only(top: spacing.sm),
          child: IntroOrChatButton(
            buttonKey: Key('matchCard.requestIntro.${widget.match.id}'),
            recipient: SendIntroRecipient(
              id: profile.id,
              name: profile.name ?? '@${profile.handle}',
              handle: profile.handle,
              photoUrl: profile.photoUrl,
              role: profile.primaryRole,
              headline: profile.headline,
            ),
            introLabel: context.t('discovery.requestIntro'),
            introVariant: widget.featured
                ? AppButtonVariant.primary
                : AppButtonVariant.outline,
            introIcon: Icons.handshake_outlined,
            size: AppButtonSize.small,
          ),
        ),
      ],
    );

    final Widget tracked =
        (widget.onSeen == null || widget.match.viewedAt != null)
            ? content
            : VisibilityDetector(
                key: Key('match-${widget.match.id}'),
                onVisibilityChanged: (info) {
                  if (_seenDispatched) return;
                  if (info.visibleFraction >= 0.5) {
                    _seenDispatched = true;
                    widget.onSeen!();
                  }
                },
                child: content,
              );

    return _CardEntrance(index: widget.entranceIndex, child: tracked);
  }
}

/// One-shot staggered fade + subtle upward slide for a daily-match card.
///
/// Runs a single short [AnimatedSlide] + [AnimatedOpacity] from a tiny offset
/// on the first frame after mount, with a per-index delay so the list cascades
/// in. State (not repeating) so it never re-triggers on rebuild and adds no
/// per-frame cost once settled.
class _CardEntrance extends StatefulWidget {
  const _CardEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_CardEntrance> createState() => _CardEntranceState();
}

class _CardEntranceState extends State<_CardEntrance> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // Cap the cumulative stagger so a long list never feels slow; clamps the
    // total entrance window to ~280ms regardless of position.
    final int delayMs = (widget.index.clamp(0, 4)) * 55;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.04),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

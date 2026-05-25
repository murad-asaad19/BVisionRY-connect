import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/intro.dart';
import 'intro_state_badge.dart';

/// One row in the Received / Sent lists.
///
/// Layout: 44px [Avatar] + a column with `peerName` + truncated note
/// snippet, and a trailing [IntroStateBadge]. Tapping the row pushes the
/// detail route. The peer's name is resolved by the inbox (typically via
/// `profileByIdProvider`) so this widget stays purely presentational.
class IntroListRow extends StatelessWidget {
  const IntroListRow({
    super.key,
    required this.intro,
    required this.peerName,
    required this.peerHandle,
    required this.peerPhotoUrl,
  });

  final Intro intro;
  final String peerName;
  final String peerHandle;
  final String? peerPhotoUrl;

  static const int _snippetMaxChars = 80;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final snippet = intro.note.length > _snippetMaxChars
        ? '${intro.note.substring(0, _snippetMaxChars).trimRight()}…'
        : intro.note;

    return InkWell(
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
                          style: typo.displaySm.copyWith(color: colors.navy),
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
    );
  }
}

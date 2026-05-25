import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/warm_suggestion.dart';
import '../providers/warm_intros_provider.dart';
import 'send_warm_request_sheet.dart';

/// Horizontal strip of 2nd-degree warm-intro suggestions for the home /
/// network surface (gallery E4).
///
/// Each card surfaces the prospective target's avatar + name, the top
/// mutual bridging the gap, and (when `mutual_count > 1`) a "+N more"
/// pill to hint at depth. Tap → opens [SendWarmRequestSheet].
///
/// Renders nothing while loading or when the list is empty so callers can
/// drop this into a vertical scroll without worrying about layout
/// collapse.
class WarmIntroSuggestionsStrip extends ConsumerWidget {
  const WarmIntroSuggestionsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WarmSuggestion>> async =
        ref.watch(warmSuggestionsProvider);
    return async.maybeWhen(
      data: (List<WarmSuggestion> rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return _Strip(rows: rows);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.rows});

  final List<WarmSuggestion> rows;

  static const double _cardWidth = 200;
  static const double _stripHeight = 184;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t('intros.warm.stripTitle'),
            style: typo.displayLg.copyWith(color: colors.navy, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _stripHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: _cardWidth,
                child: _WarmSuggestionCard(suggestion: rows[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmSuggestionCard extends StatelessWidget {
  const _WarmSuggestionCard({required this.suggestion});

  final WarmSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final extra = suggestion.mutualCount - 1;
    return Material(
      color: colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey<String>('warm-card-${suggestion.targetId}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => showSendWarmRequestSheet(context, suggestion: suggestion),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Avatar(
                    name: suggestion.targetName,
                    photoUrl: suggestion.targetPhotoUrl,
                    size: 48,
                    tone: AvatarTone.featured,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          suggestion.targetName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.displaySm.copyWith(color: colors.navy),
                        ),
                        if (suggestion.targetPrimaryRole != null)
                          Text(
                            suggestion.targetPrimaryRole!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typo.bodyMd.copyWith(color: colors.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.t(
                        'intros.warm.via_one',
                        vars: <String, Object>{
                          'name': suggestion.topMutualName,
                          'count': 1,
                        },
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typo.bodyMd.copyWith(color: colors.body),
                    ),
                  ),
                  if (extra > 0) ...[
                    const SizedBox(width: 6),
                    Pill(
                      key: ValueKey<String>(
                        'warm-card-${suggestion.targetId}-extra',
                      ),
                      label: '+$extra',
                      variant: PillVariant.muted,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              AppButton(
                key: ValueKey<String>(
                  'warm-card-${suggestion.targetId}-cta',
                ),
                label: context.t(
                  'intros.warm.askCta',
                  vars: <String, Object>{
                    'firstName': _firstName(suggestion.topMutualName),
                  },
                ),
                size: AppButtonSize.small,
                variant: AppButtonVariant.gold,
                onPressed: () =>
                    showSendWarmRequestSheet(context, suggestion: suggestion),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstName(String full) {
    final trimmed = full.trim();
    if (trimmed.isEmpty) return '';
    final i = trimmed.indexOf(' ');
    return i == -1 ? trimmed : trimmed.substring(0, i);
  }
}

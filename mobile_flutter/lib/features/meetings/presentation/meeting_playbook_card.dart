import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meeting_playbook_service.dart';
import '../domain/meeting_playbook.dart';
import '../providers/meeting_playbook_provider.dart';

/// AI-briefing card (gallery G3 / spec §4.5).
///
/// Five states:
/// 1. loading — spinner + `meetings.playbook.generating`.
/// 2. empty — "Generate playbook" CTA; tap → regenerate(force=true).
/// 3. loaded — summary + 4 expansion tiles + Regenerate button. The
///    Regenerate button is disabled within the first hour after
///    `generated_at` per spec §4.5 (client-side cooldown).
/// 4. regenerating — overlay spinner on top of the loaded content; the
///    Regenerate button is hidden while busy.
/// 5. error — banner with retry tap.
class MeetingPlaybookCard extends ConsumerStatefulWidget {
  const MeetingPlaybookCard({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingPlaybookCard> createState() =>
      _MeetingPlaybookCardState();
}

class _MeetingPlaybookCardState extends ConsumerState<MeetingPlaybookCard> {
  bool _busy = false;
  String? _error;

  Future<void> _regenerate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(meetingPlaybookServiceProvider)
          .regeneratePlaybook(widget.meetingId, force: true);
      ref.invalidate(meetingPlaybookProvider(widget.meetingId));
    } on AppException catch (e) {
      if (mounted) setState(() => _error = context.t(e.i18nKey));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.t('meetings.playbook.errorBanner'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pb = ref.watch(meetingPlaybookProvider(widget.meetingId));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: pb.when(
          loading: () => const _LoadingBlock(),
          error: (e, _) => _ErrorBlock(error: _error, onRetry: _regenerate),
          data: (data) => data == null
              ? _EmptyBlock(busy: _busy, onGenerate: _regenerate)
              : _LoadedBlock(
                  playbook: data,
                  busy: _busy,
                  error: _error,
                  onRegenerate: _regenerate,
                ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.busy, required this.onGenerate});
  final bool busy;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.sparkles, color: colors.gold, size: 32),
        const SizedBox(height: 8),
        Text(
          context.t('meetings.playbook.title'),
          style: typo.displaySm.copyWith(color: colors.navy),
        ),
        const SizedBox(height: 12),
        AppButton(
          key: const Key('playbook-generate'),
          label: context.t('meetings.playbook.generate'),
          fullWidth: false,
          loading: busy,
          onPressed: busy ? null : onGenerate,
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    final typo = Theme.of(context).extension<AppTypography>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.navy),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('meetings.playbook.generating'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final typo = Theme.of(context).extension<AppTypography>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          error ?? context.t('meetings.playbook.errorBanner'),
          style: typo.bodyLg.copyWith(color: colors.danger),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: context.t('meetings.playbook.retry'),
          variant: AppButtonVariant.outline,
          fullWidth: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _LoadedBlock extends StatelessWidget {
  const _LoadedBlock({
    required this.playbook,
    required this.busy,
    required this.error,
    required this.onRegenerate,
  });
  final MeetingPlaybook playbook;
  final bool busy;
  final String? error;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final canRegen = playbook.canRegenerate && !busy;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(playbook.summary, style: typo.bodyLg.copyWith(color: colors.body)),
        const SizedBox(height: 16),
        _Section(
          title: context.t('meetings.playbook.section.sharedInterests'),
          items: playbook.sharedInterests,
        ),
        _Section(
          title: context.t('meetings.playbook.section.conversationStarters'),
          items: playbook.conversationStarters,
        ),
        _Section(
          title: context.t('meetings.playbook.section.do'),
          items: playbook.doNotes,
        ),
        _Section(
          title: context.t('meetings.playbook.section.dont'),
          items: playbook.dontNotes,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _relativeTime(context, playbook.generatedAt),
                style: typo.bodyXs.copyWith(color: colors.muted),
              ),
            ),
            AppButton(
              key: const Key('playbook-regenerate'),
              label: canRegen
                  ? context.t('meetings.playbook.regenerate')
                  : context.t('meetings.playbook.regenerateRateLimited'),
              variant: AppButtonVariant.outline,
              fullWidth: false,
              size: AppButtonSize.small,
              onPressed: canRegen ? onRegenerate : null,
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: typo.bodyMd.copyWith(color: colors.danger),
          ),
        ],
      ],
    );

    return Stack(
      children: [
        body,
        if (busy)
          Positioned.fill(
            child: ColoredBox(
              color: colors.white.withValues(alpha: 0.6),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  String _relativeTime(BuildContext context, DateTime t) {
    final diff = DateTime.now().toUtc().difference(t);
    final ago = diff.inMinutes < 1
        ? context.t('meetings.playbook.justNow')
        : diff.inHours < 1
            ? '${diff.inMinutes}${context.t('meetings.playbook.minutesShort')}'
            : diff.inDays < 1
                ? '${diff.inHours}${context.t('meetings.playbook.hoursShort')}'
                : '${diff.inDays}${context.t('meetings.playbook.daysShort')}';
    return context.t(
      'meetings.playbook.generatedAt',
      vars: {'ago': ago},
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final typo = Theme.of(context).extension<AppTypography>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    if (items.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          title,
          style: typo.displaySm.copyWith(color: colors.navy),
        ),
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: typo.bodyMd.copyWith(color: colors.muted)),
                  Expanded(
                    child: Text(
                      item,
                      style: typo.bodyMd.copyWith(color: colors.body),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/domain/profile.dart';
import '../../profile/providers/peer_profile_provider.dart';
import '../data/warm_intros_service.dart';
import '../domain/intro.dart';
import '../domain/intro_enums.dart';
import '../providers/intros_providers.dart';
import '_intro_note_field.dart';

/// Opens the warm-forward composer for [intro]. Returns `true` once the
/// forward succeeded; `null` when the user dismissed the sheet.
///
/// `intro.kind` MUST be [IntroKind.warmRequest] — debug builds will trip
/// the assertion below if a caller mis-routes a direct/forward row here.
Future<bool?> showWarmIntroForwardSheet(
  BuildContext context, {
  required Intro intro,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    child: WarmIntroForwardSheet(intro: intro),
  );
}

/// Bottom sheet that lets the recipient of a `warm_request` intro forward
/// the introduction to its `warm_target_id` via
/// [WarmIntrosService.forwardWarmIntro]. The asker's original note is
/// echoed at the top so the forwarder can reference it in their copy.
class WarmIntroForwardSheet extends ConsumerStatefulWidget {
  WarmIntroForwardSheet({super.key, required this.intro})
      : assert(
          intro.kind == IntroKind.warmRequest,
          'WarmIntroForwardSheet expects intro.kind == warm_request; '
          'got ${intro.kind}',
        );

  final Intro intro;

  @override
  ConsumerState<WarmIntroForwardSheet> createState() =>
      _WarmIntroForwardSheetState();
}

class _WarmIntroForwardSheetState extends ConsumerState<WarmIntroForwardSheet> {
  String _note = '';
  bool _sending = false;
  String? _errorKey;

  Future<void> _forward() async {
    if (!isIntroNoteInRange(_note)) return;
    setState(() {
      _sending = true;
      _errorKey = null;
    });
    try {
      await ref.read(warmIntrosServiceProvider).forwardWarmIntro(
            introId: widget.intro.id,
            note: _note,
          );
      ref
        ..invalidate(receivedIntrosProvider)
        ..invalidate(sentIntrosProvider);
      if (!mounted) return;
      final targetName = _resolveTargetName();
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t(
              'intros.warm.forwardSuccess',
              vars: <String, Object>{'targetName': targetName},
            ),
            intent: AppIntent.success,
          );
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = _resolveErrorKey(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _resolveTargetName() {
    final targetId = widget.intro.warmTargetId;
    if (targetId == null) return '…';
    final async = ref.read(peerProfileProvider(targetId));
    return async.asData?.value?.name ?? targetId;
  }

  String _resolveErrorKey(AppException e) {
    if (e is IntroCooldownException) return 'intros.compose.errorCooldown';
    if (e is DailyCapException) return 'intros.compose.errorRateLimit';
    if (e is DuplicateException) return 'intros.compose.errorDuplicate';
    if (e is IntroNoteRangeException) return 'intros.compose.errorRange';
    if (e is WrongIntroKindException) return 'intros.compose.errorGeneric';
    return 'intros.compose.errorGeneric';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final intro = widget.intro;
    final bool valid = isIntroNoteInRange(_note);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PeerHeader(
            userId: intro.senderId,
            captionKey: 'intros.warmRequest.fromAsker',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.goldPale,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.gold),
            ),
            child: Text(
              intro.note,
              style: typo.bodyMd.copyWith(color: colors.navy),
            ),
          ),
          const SizedBox(height: 16),
          if (intro.warmTargetId != null) ...[
            _PeerHeader(
              userId: intro.warmTargetId!,
              captionKey: 'intros.warmRequest.viaMutual',
            ),
            const SizedBox(height: 12),
          ],
          Text(
            context.t('intros.warmRequest.hintBody'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 12),
          IntroNoteField(
            value: _note,
            onChanged: (v) => setState(() => _note = v),
            placeholderKey: 'intros.warm.forwardPlaceholder',
            enabled: !_sending,
          ),
          if (_errorKey != null) ...[
            const SizedBox(height: 12),
            AppBanner(
              intent: AppIntent.danger,
              child: Text(context.t(_errorKey!)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  key: const ValueKey('warm-forward-skip'),
                  label: context.t('intros.warmRequest.skipCta'),
                  variant: AppButtonVariant.outline,
                  onPressed: _sending
                      ? null
                      : () => Navigator.of(context).maybePop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  key: const ValueKey('warm-forward-send'),
                  label: context.t('intros.warmRequest.forwardCta'),
                  loading: _sending,
                  onPressed: (valid && !_sending) ? _forward : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar + name + caption row used by the sheet's "From `asker`" and
/// "Forward to `target`" sections. Resolves the peer lazily through
/// [peerProfileProvider] and falls back to the user id while loading.
class _PeerHeader extends ConsumerWidget {
  const _PeerHeader({required this.userId, required this.captionKey});

  final String userId;
  final String captionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final AsyncValue<Profile?> async = ref.watch(peerProfileProvider(userId));
    final Profile? profile = async.asData?.value;
    final String name = profile?.name ?? userId;
    return Row(
      children: <Widget>[
        Avatar(name: name, photoUrl: profile?.photoUrl, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.t(captionKey),
                style: typo.bodyXs.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typo.displaySm.copyWith(color: colors.navy),
              ),
              if (profile?.primaryRole != null)
                Text(
                  profile!.primaryRole!,
                  style: typo.bodyMd.copyWith(color: colors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

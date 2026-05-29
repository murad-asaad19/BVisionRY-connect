import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../data/warm_intros_service.dart';
import '../domain/warm_suggestion.dart';
import '../providers/intros_providers.dart';
import '../providers/warm_intros_provider.dart';
import '_intro_note_field.dart';

/// Opens the warm-request composer for [suggestion]. Returns `true` when the
/// request was successfully sent; `null` when the user backed out.
Future<bool?> showSendWarmRequestSheet(
  BuildContext context, {
  required WarmSuggestion suggestion,
}) {
  Analytics.log(
    AppEvent.introComposeOpened,
    const <String, Object>{'via_warm': true},
  );
  return showAppBottomSheet<bool>(
    context: context,
    child: SendWarmRequestSheet(suggestion: suggestion),
  );
}

/// Bottom sheet that asks `top_mutual_name` to introduce the caller to
/// `target_name`. Sends a `warm_request` intro via
/// [WarmIntrosService.sendWarmRequest].
///
/// Same 80-400 trimmed-length gating as direct compose so the SQL
/// `char_length(btrim(note))` predicate never trips the client.
class SendWarmRequestSheet extends ConsumerStatefulWidget {
  const SendWarmRequestSheet({super.key, required this.suggestion});

  final WarmSuggestion suggestion;

  @override
  ConsumerState<SendWarmRequestSheet> createState() =>
      _SendWarmRequestSheetState();
}

class _SendWarmRequestSheetState extends ConsumerState<SendWarmRequestSheet> {
  String _note = '';
  bool _sending = false;
  String? _errorKey;

  Future<void> _send() async {
    if (!isIntroNoteInRange(_note)) return;
    setState(() {
      _sending = true;
      _errorKey = null;
    });
    try {
      await ref.read(warmIntrosServiceProvider).sendWarmRequest(
            mutualId: widget.suggestion.topMutualId,
            targetId: widget.suggestion.targetId,
            note: _note,
          );
      Analytics.log(
        AppEvent.introSent,
        const <String, Object>{'via_warm': true},
      );
      ref
        ..invalidate(sentIntrosProvider)
        ..invalidate(warmSuggestionsProvider);
      if (!mounted) return;
      // Medium impact — confirms the warm request was sent.
      Haptics.medium();
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t(
              'intros.warm.composeSuccess',
              vars: <String, Object>{
                'mutualName': widget.suggestion.topMutualName,
              },
            ),
            intent: AppIntent.success,
          );
      // Defer the pop one frame so the toast lands before the sheet tears
      // down — see T-INTRO-SEND-TOAST-RACE.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    } on AppException catch (e) {
      Analytics.log(
        AppEvent.introSendFailed,
        const <String, Object>{'via_warm': true},
      );
      if (!mounted) return;
      setState(() => _errorKey = _resolveErrorKey(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
    final bool valid = isIntroNoteInRange(_note);
    final s = widget.suggestion;
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
          _WarmRequestHeader(suggestion: s),
          const SizedBox(height: 16),
          IntroNoteField(
            value: _note,
            onChanged: (v) => setState(() => _note = v),
            placeholderKey: 'intros.warm.composePlaceholder',
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
                  label: context.t('intros.compose.cancel'),
                  variant: AppButtonVariant.outline,
                  onPressed: _sending
                      ? null
                      : () => Navigator.of(context).maybePop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  key: const ValueKey('send-warm-request-send'),
                  label: context.t('intros.warm.composeSubmit'),
                  loading: _sending,
                  onPressed: (valid && !_sending) ? _send : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarmRequestHeader extends StatelessWidget {
  const _WarmRequestHeader({required this.suggestion});

  final WarmSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.t(
            'intros.warm.composeTitle',
            vars: <String, Object>{'mutualName': suggestion.topMutualName},
          ),
          style: typo.displayLg.copyWith(color: colors.navy, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Avatar(
              name: suggestion.targetName,
              photoUrl: suggestion.targetPhotoUrl,
              size: 32,
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
                  Text(
                    '@${suggestion.targetHandle}',
                    style: typo.bodyMd.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            Pill(
              variant: PillVariant.outline,
              label: context.t(
                'intros.warm.via_one',
                vars: <String, Object>{
                  'name': suggestion.topMutualName,
                  'count': 1,
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

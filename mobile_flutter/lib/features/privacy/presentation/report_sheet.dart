import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/privacy_service.dart';
import '../domain/report_reason.dart';
import '../domain/report_target_type.dart';

/// Opens the Report bottom sheet polymorphically against a profile, a
/// message, or an intro. Returns `true` if the report was submitted, `false`
/// when the user dismissed without submitting (or submission failed).
///
/// `quotedMessageId` + `quotedBodyPreview` are meaningful only when
/// [targetType] is `ReportTargetType.message` — chat callers pre-populate
/// them from the message bubble's source row so the report carries the
/// quoted body server-side for moderation review.
Future<bool> showReportSheet(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
  String? quotedMessageId,
  String? quotedBodyPreview,
}) async {
  final bool? result = await showAppBottomSheet<bool>(
    context: context,
    child: _ReportSheetBody(
      targetType: targetType,
      targetId: targetId,
      quotedMessageId: quotedMessageId,
      quotedBodyPreview: quotedBodyPreview,
    ),
  );
  return result ?? false;
}

class _ReportSheetBody extends ConsumerStatefulWidget {
  const _ReportSheetBody({
    required this.targetType,
    required this.targetId,
    this.quotedMessageId,
    this.quotedBodyPreview,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String? quotedMessageId;
  final String? quotedBodyPreview;

  @override
  ConsumerState<_ReportSheetBody> createState() => _ReportSheetBodyState();
}

class _ReportSheetBodyState extends ConsumerState<_ReportSheetBody> {
  ReportReason? _reason;
  String _note = '';
  bool _submitting = false;
  String? _errorKey;

  Future<void> _submit() async {
    if (_reason == null) {
      setState(() => _errorKey = 'privacy.reportModal.pickReasonBody');
      return;
    }
    setState(() {
      _submitting = true;
      _errorKey = null;
    });
    try {
      await ref.read(privacyServiceProvider).reportTarget(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: _reason!,
            note: _note.isEmpty ? null : _note,
            quotedMessageId: widget.quotedMessageId,
          );
      if (!mounted) return;
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('privacy.reportModal.sentTitle'),
            body: context.t('privacy.reportModal.sentBody'),
            intent: AppIntent.success,
          );
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorKey = e.i18nKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo =
        Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.t('privacy.reportModal.title'),
              style: typo.displayLg.copyWith(color: colors.navy),
            ),
            const SizedBox(height: 12),
            if (widget.quotedBodyPreview != null) ...<Widget>[
              _QuotedPreview(body: widget.quotedBodyPreview!),
              const SizedBox(height: 12),
            ],
            // 5 outline-style buttons stacked, full-width, with the picked
            // one upgraded to the primary variant so the user sees their
            // choice without the button collapsing into a smaller chip.
            for (final ReportReason r in ReportReason.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppButton(
                  label: context.t(r.i18nKey),
                  variant: _reason == r
                      ? AppButtonVariant.primary
                      : AppButtonVariant.outline,
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _reason = r;
                            if (_errorKey == 'privacy.reportModal.pickReasonBody') {
                              _errorKey = null;
                            }
                          }),
                ),
              ),
            const SizedBox(height: 4),
            AppInput(
              label: context.t('privacy.reportModal.noteLabel'),
              placeholder: context.t('privacy.reportModal.notePlaceholder'),
              value: _note,
              multiline: true,
              minLines: 3,
              maxLines: 6,
              maxLength: PrivacyService.kReportNoteMaxChars,
              onChanged: (String v) => setState(() => _note = v),
            ),
            if (_errorKey != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                context.t(_errorKey!),
                style: typo.bodySm.copyWith(color: colors.danger),
              ),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: context.t('privacy.reportModal.submit'),
              variant: AppButtonVariant.danger,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quoted message preview block — 3px left border in danger, muted surface,
/// max 3 lines. Used only when the report originates from a chat bubble.
class _QuotedPreview extends StatelessWidget {
  const _QuotedPreview({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo =
        Theme.of(context).extension<AppTypography>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(left: BorderSide(color: colors.danger, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.t('privacy.reportModal.quoted'),
            style: typo.bodyXs.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: typo.bodyMd.copyWith(color: colors.body),
          ),
        ],
      ),
    );
  }
}

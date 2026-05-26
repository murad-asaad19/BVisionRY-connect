import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/variants.dart';
import '../data/opportunities_service.dart';
import '../providers/opportunity_provider.dart';

const int _kMaxNoteLength = 500;
const int _kMinNoteLength = 10;

/// Opens the Express Interest bottom sheet for [opportunityId]. Returns
/// `true` on success (the caller invalidates the detail provider), `false`
/// when the user dismisses without sending.
Future<bool> showExpressInterestSheet(
  BuildContext context, {
  required String opportunityId,
}) async {
  final bool? result = await showAppBottomSheet<bool>(
    context: context,
    child: _ExpressInterestSheetBody(opportunityId: opportunityId),
  );
  return result ?? false;
}

class _ExpressInterestSheetBody extends ConsumerStatefulWidget {
  const _ExpressInterestSheetBody({required this.opportunityId});

  final String opportunityId;

  @override
  ConsumerState<_ExpressInterestSheetBody> createState() =>
      _ExpressInterestSheetBodyState();
}

class _ExpressInterestSheetBodyState
    extends ConsumerState<_ExpressInterestSheetBody> {
  String _note = '';
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final String trimmed = _note.trim();
    final String? note = trimmed.isEmpty ? null : trimmed;
    if (note != null && note.length < _kMinNoteLength) {
      setState(() {
        _error = context.t('opportunities.interest.errorNoteRange');
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(opportunitiesServiceProvider).expressInterest(
            opportunityId: widget.opportunityId,
            note: note,
          );
      ref.invalidate(opportunityProvider(widget.opportunityId));
      if (!mounted) return;
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('opportunities.interest.success'),
            intent: AppIntent.success,
          );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final String key =
          e is AppException ? e.i18nKey : 'opportunities.interest.errorGeneric';
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t(key),
            intent: AppIntent.danger,
          );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t('opportunities.detail.expressInterestCta'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('opportunities.interest.subtitle'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 16),
          AppInput(
            placeholder: context.t('opportunities.interest.notePlaceholder'),
            value: _note,
            onChanged: (String v) => setState(() {
              _note = v;
              if (_error != null) _error = null;
            }),
            multiline: true,
            minLines: 3,
            maxLines: 6,
            maxLength: _kMaxNoteLength,
            errorText: _error,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: context.t('opportunities.interest.submit'),
            variant: AppButtonVariant.gold,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

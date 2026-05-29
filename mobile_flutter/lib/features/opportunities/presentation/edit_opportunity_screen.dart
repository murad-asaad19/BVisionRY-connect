import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../data/opportunities_service.dart';
import '../domain/opportunity_with_counts.dart';
import '../providers/my_opportunities_provider.dart';
import '../providers/opportunities_feed_provider.dart';
import '../providers/opportunity_provider.dart';
import 'opportunity_form.dart';
import 'unsaved_changes_guard.dart';

/// Author-only edit screen for an existing opportunity.
///
/// Watches [opportunityProvider] for the current data, pre-populates the
/// shared [OpportunityForm], and on submit issues `update_opportunity`,
/// invalidates the relevant providers, and pops back to the detail screen.
class EditOpportunityScreen extends ConsumerStatefulWidget {
  const EditOpportunityScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  ConsumerState<EditOpportunityScreen> createState() =>
      _EditOpportunityScreenState();
}

class _EditOpportunityScreenState extends ConsumerState<EditOpportunityScreen> {
  bool _submitting = false;
  bool _dirty = false;

  Future<void> _submit(OpportunityFormValue v) async {
    if (v.kind == null) return;
    // Submitting commits the edits, so the unsaved-changes guard must stand
    // down before we pop on success.
    _dirty = false;
    setState(() => _submitting = true);
    try {
      await ref.read(opportunitiesServiceProvider).updateOpportunity(
            id: widget.opportunityId,
            kind: v.kind!,
            title: v.title,
            body: v.body,
            tags: v.tags.value,
            locationCity: v.locationCity.isEmpty ? null : v.locationCity,
            locationCountry:
                v.locationCountry.isEmpty ? null : v.locationCountry,
            remoteOk: v.remoteOk,
            expiresAt: v.expiresAt,
          );
      ref.invalidate(opportunityProvider(widget.opportunityId));
      ref.invalidate(myOpportunitiesProvider);
      ref.invalidate(opportunitiesFeedProvider);
      if (!mounted) return;
      // Light tick to confirm the edits were saved.
      Haptics.light();
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('opportunities.edit.submitSuccess'),
            intent: AppIntent.success,
          );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final String key =
          e is AppException ? e.i18nKey : 'opportunities.composer.errorSubmit';
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t(key),
            intent: AppIntent.danger,
          );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OpportunityWithCounts> async =
        ref.watch(opportunityProvider(widget.opportunityId));
    return UnsavedChangesGuard(
      isDirty: _dirty && !_submitting,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              TopBar(
                title: context.t('opportunities.edit.title'),
                back: true,
              ),
              Expanded(
                child: QueryState<OpportunityWithCounts>(
                  value: async,
                  onRetry: () =>
                      ref.invalidate(opportunityProvider(widget.opportunityId)),
                  data: (OpportunityWithCounts d) {
                    return OpportunityForm(
                      initial: OpportunityFormValue.fromOpportunity(
                        d.withAuthor.opportunity,
                      ),
                      onSubmit: _submit,
                      onDirtyChanged: (bool v) => setState(() => _dirty = v),
                      submitLabel: _submitting
                          ? context.t('opportunities.edit.submitting')
                          : context.t('opportunities.edit.submit'),
                      submitting: _submitting,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

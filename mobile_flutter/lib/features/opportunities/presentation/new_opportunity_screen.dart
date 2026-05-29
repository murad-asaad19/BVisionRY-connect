import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../data/opportunities_service.dart';
import '../providers/my_opportunities_provider.dart';
import '../providers/opportunities_feed_provider.dart';
import 'opportunity_form.dart';
import 'unsaved_changes_guard.dart';

/// Composer screen for a brand-new opportunity.
///
/// On submit:
///   1. Calls `service.createOpportunity(...)`.
///   2. Invalidates `opportunitiesFeedProvider` + `myOpportunitiesProvider`
///      so the feed and "mine" lists refresh on the next view.
///   3. Shows a success toast and `context.replace(Routes.opportunity(id))`
///      so back-navigation lands on the feed, not the now-stale composer.
class NewOpportunityScreen extends ConsumerStatefulWidget {
  const NewOpportunityScreen({super.key});

  @override
  ConsumerState<NewOpportunityScreen> createState() =>
      _NewOpportunityScreenState();
}

class _NewOpportunityScreenState extends ConsumerState<NewOpportunityScreen> {
  bool _submitting = false;
  bool _dirty = false;

  Future<void> _submit(OpportunityFormValue v) async {
    if (v.kind == null) return;
    // Submitting commits the edits, so the unsaved-changes guard must stand
    // down before we navigate away on success.
    _dirty = false;
    setState(() => _submitting = true);
    try {
      final String id =
          await ref.read(opportunitiesServiceProvider).createOpportunity(
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
      ref.invalidate(opportunitiesFeedProvider);
      ref.invalidate(myOpportunitiesProvider);
      if (!mounted) return;
      // Light tick to confirm the opportunity was posted.
      Haptics.light();
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('opportunities.composer.submitSuccess'),
            intent: AppIntent.success,
          );
      context.replace(Routes.opportunity(id));
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
    return UnsavedChangesGuard(
      isDirty: _dirty && !_submitting,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              TopBar(
                title: context.t('opportunities.feed.newCta'),
                back: true,
              ),
              Expanded(
                child: OpportunityForm(
                  onSubmit: _submit,
                  onDirtyChanged: (bool v) => setState(() => _dirty = v),
                  submitLabel: _submitting
                      ? context.t('opportunities.composer.submitting')
                      : context.t('opportunities.composer.submit'),
                  submitting: _submitting,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

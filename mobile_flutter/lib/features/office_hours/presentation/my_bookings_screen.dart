import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../data/office_hours_service.dart';
import '../domain/my_booking.dart';
import '../providers/my_bookings_provider.dart';
import 'widgets/booking_card.dart';

/// `/bookings` — the user's list of upcoming office-hours bookings.
///
/// Reads [myBookingsProvider] (which auto-refreshes on
/// [AppLifecycleState.resumed]). Tapping a card opens the canonical chat
/// for that booking; cancelling pops a destructive ConfirmDialog before
/// calling `cancel_booking` and refreshing the list.
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBookingsProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('officeHours.bookings.title'),
          back: Navigator.of(context).canPop(),
        ),
      ),
      body: QueryState<List<MyBooking>>(
        value: async,
        onRetry: () => ref.invalidate(myBookingsProvider),
        data: (rows) {
          if (rows.isEmpty) {
            return EmptyState(
              icon: Icons.event_busy,
              title: context.t('officeHours.bookings.emptyTitle'),
              body: context.t('officeHours.bookings.emptyBody'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _Row(booking: rows[i]),
          );
        },
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.booking});
  final MyBooking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookingCard(
      booking: booking,
      onTap: () => _openChat(context, ref),
      onCancel: () => _cancel(context, ref),
    );
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final pid = booking.meetingProposalId;
    if (pid == null) return;
    final toast = ref.read(toastServiceProvider.notifier);
    final translator = context.t;
    try {
      final convId = await ref
          .read(officeHoursServiceProvider)
          .conversationIdForProposal(pid);
      if (!context.mounted) return;
      // Use go_router's maybeOf so a missing router in unit tests is a
      // graceful no-op rather than a throw.
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        unawaited(router.push(Routes.chat(convId)));
      }
    } on AppException catch (e) {
      toast.showToast(
        title: translator(e.i18nKey),
        intent: AppIntent.danger,
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmSvc = ref.read(confirmServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final translator = context.t;
    final ok = await confirmSvc.confirm(
      context,
      title: translator('officeHours.bookings.cancelConfirm'),
      body: translator('officeHours.bookings.cancelConfirmBody'),
      destructive: true,
      confirmLabel: translator('officeHours.bookings.cancel'),
      cancelLabel: translator('common.cancel'),
    );
    if (!ok) return;
    try {
      await ref.read(officeHoursServiceProvider).cancelBooking(booking.slotId);
      await ref.read(myBookingsProvider.notifier).refresh();
      toast.showToast(
        title: translator('officeHours.bookings.cancelled'),
        intent: AppIntent.success,
      );
    } on AppException catch (e) {
      toast.showToast(
        title: translator(e.i18nKey),
        intent: AppIntent.danger,
      );
    }
  }
}

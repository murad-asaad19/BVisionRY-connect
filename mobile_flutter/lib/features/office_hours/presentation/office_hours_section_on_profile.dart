import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/variants.dart';
import '../data/office_hours_service.dart';
import '../domain/office_hours_slot.dart';
import '../providers/my_bookings_provider.dart';
import '../providers/upcoming_slots_provider.dart';
import 'widgets/slot_card.dart';

/// Embedded "Book a slot" section rendered inside another user's profile.
///
/// Behaviour:
/// - Loads `list_upcoming_slots(hostId)` via [upcomingSlotsProvider].
/// - Empty list -> `EmptyState` keyed to `officeHours.bookings.slotsEmpty*`.
/// - Non-empty -> list of [SlotCard]s; book triggers the full booking flow:
///     1. Call `book_slot(slotId, topic)`.
///     2. Resolve `conversation_id` for the returned `meeting_proposal_id`.
///     3. Invalidate the slot list + my-bookings list.
///     4. Navigate to `/chats/:conversation_id`.
///     5. On [AppException] (any of the 8 `book_slot` HINTs), show
///        `Toast.error(context.t(e.i18nKey))`.
class OfficeHoursSectionOnProfile extends ConsumerWidget {
  const OfficeHoursSectionOnProfile({super.key, required this.hostId});

  final String hostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(upcomingSlotsProvider(hostId));
    return SectionCard(
      title: context.t('officeHours.profile.sectionTitle'),
      child: QueryState<List<OfficeHoursSlot>>(
        value: async,
        onRetry: () => ref.invalidate(upcomingSlotsProvider(hostId)),
        data: (slots) {
          if (slots.isEmpty) {
            return EmptyState(
              icon: Icons.event_busy,
              title: context.t('officeHours.bookings.slotsEmptyTitle'),
              body: context.t('officeHours.bookings.slotsEmptyBody'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < slots.length; i++) ...<Widget>[
                SlotCard(
                  slot: slots[i],
                  onBook: (slotId, topic) => _book(context, ref, slotId, topic),
                ),
                if (i < slots.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _book(
    BuildContext context,
    WidgetRef ref,
    String slotId,
    String topic,
  ) async {
    final toast = ref.read(toastServiceProvider.notifier);
    final translator = context.t;
    try {
      final svc = ref.read(officeHoursServiceProvider);
      final proposalId = await svc.bookSlot(slotId: slotId, topic: topic);
      final convId = await svc.conversationIdForProposal(proposalId);
      ref
        ..invalidate(upcomingSlotsProvider(hostId))
        ..invalidate(myBookingsProvider);
      toast.showToast(
        title: translator('officeHours.book.success'),
        intent: AppIntent.success,
      );
      if (!context.mounted) return;
      // Use go_router's context extension so a missing router in unit
      // tests just no-ops rather than throwing — keeps the booking flow
      // testable without spinning up a full MaterialApp.router harness.
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
}

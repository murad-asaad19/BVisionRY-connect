import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gap.dart';
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
/// - Rendered as a no-op on the viewer's OWN profile (`viewer == hostId`) —
///   the server rejects self-booking, so we never show the section there.
/// - Loads `list_upcoming_slots(hostId)` via [upcomingSlotsProvider].
/// - Empty list -> `EmptyState` with a refresh action.
/// - Non-empty -> list of [SlotCard]s; the card that is mid-booking is put
///   into its `loading` state so it can't be double-submitted. Booking:
///     1. Call `book_slot(slotId, topic)`.
///     2. Resolve `conversation_id` for the returned `meeting_proposal_id`.
///     3. Invalidate the slot list + my-bookings list.
///     4. Navigate to `/chats/:conversation_id`.
///     5. On [AppException], show a localized error toast.
class OfficeHoursSectionOnProfile extends ConsumerStatefulWidget {
  const OfficeHoursSectionOnProfile({super.key, required this.hostId});

  final String hostId;

  @override
  ConsumerState<OfficeHoursSectionOnProfile> createState() =>
      _OfficeHoursSectionOnProfileState();
}

class _OfficeHoursSectionOnProfileState
    extends ConsumerState<OfficeHoursSectionOnProfile> {
  /// Id of the slot whose booking is currently in flight, or null. Used to
  /// flip the matching [SlotCard] into its loading state and block a second
  /// submit while `book_slot` is round-tripping.
  String? _bookingSlotId;

  @override
  Widget build(BuildContext context) {
    final viewerId = ref.watch(officeHoursViewerIdProvider);
    // Never render the booking surface on the host's own profile.
    if (viewerId == widget.hostId) return const SizedBox.shrink();

    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final async = ref.watch(upcomingSlotsProvider(widget.hostId));
    return SectionCard(
      title: context.t('officeHours.profile.sectionTitle'),
      child: QueryState<List<OfficeHoursSlot>>(
        value: async,
        onRetry: () => ref.invalidate(upcomingSlotsProvider(widget.hostId)),
        data: (slots) {
          if (slots.isEmpty) {
            return EmptyState(
              icon: Icons.event_busy,
              title: context.t('officeHours.bookings.slotsEmptyTitle'),
              body: context.t('officeHours.bookings.slotsEmptyBody'),
              action: EmptyStateAction(
                label: context.t('common.refresh'),
                onPressed: () =>
                    ref.invalidate(upcomingSlotsProvider(widget.hostId)),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < slots.length; i++) ...<Widget>[
                SlotCard(
                  slot: slots[i],
                  loading: _bookingSlotId == slots[i].id,
                  onBook: _book,
                ),
                if (i < slots.length - 1) Gap(spacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _book(String slotId, String topic) async {
    // Guard against a double-submit while one booking is already in flight.
    if (_bookingSlotId != null) return;
    setState(() => _bookingSlotId = slotId);
    final toast = ref.read(toastServiceProvider.notifier);
    final translator = context.t;
    try {
      final svc = ref.read(officeHoursServiceProvider);
      final proposalId = await svc.bookSlot(slotId: slotId, topic: topic);
      final convId = await svc.conversationIdForProposal(proposalId);
      Haptics.medium();
      ref
        ..invalidate(upcomingSlotsProvider(widget.hostId))
        ..invalidate(myBookingsProvider);
      toast.showToast(
        title: translator('officeHours.book.success'),
        intent: AppIntent.success,
      );
      if (!mounted) return;
      // Use go_router's context extension so a missing router in unit
      // tests just no-ops rather than throwing — keeps the booking flow
      // testable without spinning up a full MaterialApp.router harness.
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        unawaited(router.push(Routes.chat(convId)));
      }
    } on AppException catch (e) {
      Haptics.error();
      if (!mounted) return;
      toast.showToast(
        title: messageForError(context, e),
        intent: AppIntent.danger,
      );
    } finally {
      if (mounted) setState(() => _bookingSlotId = null);
    }
  }
}

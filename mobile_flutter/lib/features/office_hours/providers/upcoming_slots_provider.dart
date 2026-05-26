import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/office_hours_service.dart';
import '../domain/office_hours_slot.dart';

/// `list_upcoming_slots(p_host)` (spec §3.6) — family keyed by `hostId`,
/// returns the list of `open` future slots for that host over the next 14
/// days. Invalidated by the booking flow once a `book_slot` succeeds so
/// the just-grabbed slot disappears from the list.
final AutoDisposeFutureProviderFamily<List<OfficeHoursSlot>, String>
    upcomingSlotsProvider =
    FutureProvider.autoDispose.family<List<OfficeHoursSlot>, String>(
  (ref, hostId) async {
    final svc = ref.watch(officeHoursServiceProvider);
    return svc.listUpcomingSlots(hostId);
  },
);

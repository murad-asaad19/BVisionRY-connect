import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/session_provider.dart';
import '../data/office_hours_service.dart';
import '../domain/office_hours_slot.dart';

/// The signed-in viewer's user id, or null when anonymous / unresolved.
///
/// Exposed as its own provider so the profile booking section can suppress
/// itself on the host's OWN profile (`viewer == host`) and so widget tests
/// can inject a viewer without standing up the full Supabase auth stack
/// (`officeHoursViewerIdProvider.overrideWithValue('me')`).
///
/// Resolving the session reaches into the Supabase client; if that isn't
/// available (e.g. a lightweight widget test that never initialised it), we
/// fall back to `null` — an unknown viewer renders the section, which is the
/// safe default since the server still rejects self-booking.
final Provider<String?> officeHoursViewerIdProvider = Provider<String?>((ref) {
  try {
    return ref.watch(currentSessionProvider)?.user.id;
  } catch (_) {
    return null;
  }
});

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

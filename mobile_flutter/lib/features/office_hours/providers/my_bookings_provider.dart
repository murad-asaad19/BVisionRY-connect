import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/office_hours_service.dart';
import '../domain/my_booking.dart';

/// Observer that fires [onResume] every time the app returns to the
/// foreground. Kept private to this file because the only consumer is
/// the [MyBookingsNotifier] below.
class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);
  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// AsyncNotifier wrapping `my_bookings()` with a foreground auto-refresh.
///
/// Registers a [WidgetsBindingObserver] on first build and invalidates
/// itself whenever the app resumes — guarantees the bookings list stays
/// fresh after the user dips out to a calendar app and comes back.
///
/// The observer is removed in [ref.onDispose] so the registration doesn't
/// outlive the provider container.
class MyBookingsNotifier extends AsyncNotifier<List<MyBooking>> {
  _ResumeObserver? _observer;

  @override
  Future<List<MyBooking>> build() async {
    _observer = _ResumeObserver(() => ref.invalidateSelf());
    WidgetsBinding.instance.addObserver(_observer!);
    ref.onDispose(() {
      final obs = _observer;
      if (obs != null) WidgetsBinding.instance.removeObserver(obs);
      _observer = null;
    });
    final svc = ref.watch(officeHoursServiceProvider);
    return svc.myBookings();
  }

  /// Explicit refresh — used by the My Bookings screen after a successful
  /// `cancel_booking` call.
  Future<void> refresh() async {
    state = const AsyncValue<List<MyBooking>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(
      ref.read(officeHoursServiceProvider).myBookings,
    );
  }
}

final AsyncNotifierProvider<MyBookingsNotifier, List<MyBooking>>
    myBookingsProvider =
    AsyncNotifierProvider<MyBookingsNotifier, List<MyBooking>>(
        MyBookingsNotifier.new);

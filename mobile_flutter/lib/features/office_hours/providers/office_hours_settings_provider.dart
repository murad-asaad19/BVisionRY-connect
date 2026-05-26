import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/office_hours_service.dart';
import '../domain/office_hours_settings.dart';

/// AsyncNotifier wrapping the caller's `my_office_hours_settings()` row
/// with a [save] mutation that re-issues `set_office_hours` and refreshes
/// the cached value in-place.
///
/// Use from the host-side Office Hours settings screen:
/// `ref.watch(officeHoursSettingsProvider)` for the current state and
/// `ref.read(officeHoursSettingsProvider.notifier).save(next)` to persist.
class OfficeHoursSettingsNotifier extends AsyncNotifier<OfficeHoursSettings> {
  @override
  Future<OfficeHoursSettings> build() async {
    final svc = ref.watch(officeHoursServiceProvider);
    return svc.myOfficeHoursSettings();
  }

  /// Persist [next] via `set_office_hours` and replace the cached row.
  ///
  /// Surfaces the typed [AppException] from the service unchanged so the
  /// screen can render a toast with the localized `e.i18nKey`.
  Future<void> save(OfficeHoursSettings next) async {
    final svc = ref.read(officeHoursServiceProvider);
    state =
        const AsyncValue<OfficeHoursSettings>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => svc.setOfficeHours(
        enabled: next.enabled,
        windows: next.windows,
        slotDurationMinutes: next.slotDurationMinutes,
        maxBookingsPerWeek: next.maxBookingsPerWeek,
        bufferMinutes: next.bufferMinutes,
        meetingLinkTemplate: next.meetingLinkTemplate,
        notesTemplate: next.notesTemplate,
      ),
    );
  }
}

final AsyncNotifierProvider<OfficeHoursSettingsNotifier, OfficeHoursSettings>
    officeHoursSettingsProvider =
    AsyncNotifierProvider<OfficeHoursSettingsNotifier, OfficeHoursSettings>(
  OfficeHoursSettingsNotifier.new,
);

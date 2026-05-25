import 'package:connect_mobile/features/discovery/providers/midnight_invalidator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('currentLocalDay returns y/m/d truncated to local midnight', () {
    final fake = FakeClock(DateTime(2026, 5, 25, 14, 33));
    final container = ProviderContainer(
      overrides: <Override>[clockProvider.overrideWithValue(fake.now)],
    );
    addTearDown(container.dispose);
    final d = container.read(currentLocalDayProvider);
    expect(d.year, 2026);
    expect(d.month, 5);
    expect(d.day, 25);
    expect(d.hour, 0);
    expect(d.minute, 0);
  });

  test('bumpIfRolled advances day when clock crossed midnight', () {
    final fake = FakeClock(DateTime(2026, 5, 25, 23, 59));
    final container = ProviderContainer(
      overrides: <Override>[clockProvider.overrideWithValue(fake.now)],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(midnightInvalidatorProvider.notifier);
    expect(container.read(currentLocalDayProvider).day, 25);

    fake.advance(const Duration(minutes: 2));
    ctrl.bumpIfRolled();
    expect(container.read(currentLocalDayProvider).day, 26);
  });
}

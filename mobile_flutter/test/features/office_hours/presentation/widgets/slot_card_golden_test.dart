import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/presentation/widgets/slot_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../../helpers/pump.dart';

void main() {
  testGoldens('SlotCard default', (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SlotCard(
            slot: OfficeHoursSlot(
              id: 's1',
              hostId: 'h1',
              startsAt: DateTime.utc(2030, 6, 1, 15, 0),
              endsAt: DateTime.utc(2030, 6, 1, 15, 30),
              hostNotesTemplate: 'Bring a 1-pager about your idea.',
            ),
            onBook: (_, __) async {},
          ),
        ),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 360),
    );
    await screenMatchesGolden(tester, 'slot_card_default');
  });
}

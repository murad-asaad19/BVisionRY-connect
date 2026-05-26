import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/privacy/data/privacy_service.dart';
import 'package:connect_mobile/features/privacy/domain/report_target_type.dart';
import 'package:connect_mobile/features/privacy/presentation/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump.dart';

class _FakeService extends Mock implements PrivacyService {}

Future<void> _pumpAndOpen(
  WidgetTester tester, {
  String? preview,
}) async {
  final _FakeService svc = _FakeService();
  final loader = await primedLocaleLoader();
  // ProviderScope MUST sit above MaterialApp — otherwise the bottom sheet
  // pushed by `showModalBottomSheet` lives in the MaterialApp Navigator's
  // overlay (outside any descendant ProviderScope) and `context.t(...)`
  // throws `No ProviderScope found`. Use `noWrap` to disable the default
  // `materialAppWrapper` and supply our own root.
  await tester.pumpWidgetBuilder(
    ProviderScope(
      overrides: <Override>[
        localeLoaderProvider.overrideWithValue(loader),
        privacyServiceProvider.overrideWithValue(svc),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (BuildContext ctx) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showReportSheet(
                ctx,
                targetType: preview == null
                    ? ReportTargetType.profile
                    : ReportTargetType.message,
                targetId: preview == null ? 'p1' : 'm1',
                quotedMessageId: preview == null ? null : 'm1',
                quotedBodyPreview: preview,
              );
            });
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    ),
    wrapper: noWrap(),
    surfaceSize: const Size(390, 760),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  testGoldens('ReportSheet — profile target (no quote)', (tester) async {
    await _pumpAndOpen(tester);
    await screenMatchesGolden(tester, 'report_sheet_profile');
  });

  testGoldens('ReportSheet — message target (with quote)', (tester) async {
    await _pumpAndOpen(
      tester,
      preview: 'You should DM me about pricing for the package',
    );
    await screenMatchesGolden(tester, 'report_sheet_message');
  });
}

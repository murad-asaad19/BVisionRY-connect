import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/i18n/locale_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/settings_group.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/top_bar.dart';
import '../settings_providers.dart';

/// `/settings/language` — single-pick locale toggle for English / Spanish.
///
/// The current selection is sourced from [localeProvider]; tapping a row
/// persists the new code via [LanguageService.save] and flips the provider
/// so subsequent `context.t(...)` calls resolve against the freshly-loaded
/// bundle. [localeReadyProvider] is invalidated so the await-loader gate
/// re-fires.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final String current = ref.watch(localeProvider).languageCode;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('settings.language.title'),
          back: true,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          SettingsGroupEyebrow(label: context.t('settings.groups.appLanguage')),
          SettingsGroupCard(
            children: <Widget>[
              for (final String code in const <String>['en', 'es'])
                SettingsRow(
                  key: Key('lang.$code'),
                  label: context.t('settings.language.$code'),
                  trailing: current == code
                      ? Icon(LucideIcons.check, size: 18, color: colors.gold)
                      : null,
                  onTap: () async {
                    await ref.read(languageServiceProvider).save(Locale(code));
                    ref.read(localeProvider.notifier).state = Locale(code);
                    ref.invalidate(localeReadyProvider);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

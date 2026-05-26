import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/i18n/i18n.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../core/widgets/variants.dart';
import '../../data/settings_service.dart';

/// File-share callback typedef. Injectable so widget tests can assert the
/// path passed to the share sheet without invoking the platform channel.
typedef ShareFile = Future<void> Function(String path);

/// Settings row that drives the GDPR data-export pipeline:
///
///   1. `export_my_data` RPC → JSON aggregate.
///   2. Write JSON to a tempfile under [getTemporaryDirectory].
///   3. Hand the file path to [shareFile] (defaults to
///      `Share.shareXFiles([XFile(path)])`).
///
/// Failures surface as a danger toast keyed to `settings.exportFailed`.
class ExportDataTile extends ConsumerWidget {
  // `shareFile` resolves a function default at construction time so a
  // const ctor is impossible.
  // ignore: prefer_const_constructors_in_immutables
  ExportDataTile({super.key, ShareFile? shareFile})
      : shareFile = shareFile ?? _defaultShare;

  /// Test-injectable share callback. Production calls share_plus directly.
  final ShareFile shareFile;

  static Future<void> _defaultShare(String path) async {
    await Share.shareXFiles(<XFile>[XFile(path)]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsRow(
      key: const Key('settings.exportTile'),
      icon: LucideIcons.download,
      label: context.t('settings.exportData'),
      onTap: () async {
        try {
          final Map<String, dynamic> data =
              await ref.read(settingsServiceProvider).exportMyData();
          final Directory dir = await getTemporaryDirectory();
          final File file = File(
            '${dir.path}/connect_export_${DateTime.now().millisecondsSinceEpoch}.json',
          );
          await file.writeAsString(jsonEncode(data));
          await shareFile(file.path);
        } on AppException catch (e) {
          if (context.mounted) {
            ref.read(toastServiceProvider.notifier).showToast(
                  intent: AppIntent.danger,
                  title: context.t(e.i18nKey),
                );
          }
        } catch (_) {
          if (context.mounted) {
            ref.read(toastServiceProvider.notifier).showToast(
                  intent: AppIntent.danger,
                  title: context.t('settings.exportFailed'),
                );
          }
        }
      },
    );
  }
}

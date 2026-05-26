import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/push/fcm_service.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/fcm_lifecycle_provider.dart';
import '../providers/push_permission_provider.dart';

/// Inline banner that surfaces the "Enable notifications" gallery affordance
/// (section I6) at the top of the home screen.
///
/// The visible state is driven by the persisted [PushPermissionBanner] flag
/// in [SharedPreferences]:
///   - `shouldShow == true`  → banner renders.
///   - `shouldShow == false` → collapses to a zero-height SizedBox.
///
/// Tapping "Enable" requests the OS push-permission, marks the banner as
/// shown (so we never nag), and lets [fcmLifecycleProvider] pick up the
/// freshly granted token via its normal lifecycle.
///
/// Renders nothing when `Env.firebaseEnabled == false` (Expo Go parity and
/// dev rigs that don't ship google-services.json).
class PushPermissionBannerWidget extends ConsumerStatefulWidget {
  const PushPermissionBannerWidget({super.key});

  @override
  ConsumerState<PushPermissionBannerWidget> createState() =>
      _PushPermissionBannerWidgetState();
}

class _PushPermissionBannerWidgetState
    extends ConsumerState<PushPermissionBannerWidget> {
  /// Tri-state visibility:
  ///   - `null`  → SharedPreferences hasn't resolved yet, collapse.
  ///   - `true`  → render the banner.
  ///   - `false` → user already dismissed / enabled, collapse for the
  ///     remainder of the session.
  bool? _visible;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!Env.firebaseEnabled) {
      if (!mounted) return;
      setState(() => _visible = false);
      return;
    }
    final PushPermissionBanner store =
        ref.read(pushPermissionBannerProvider);
    final bool show = await store.shouldShow();
    if (!mounted) return;
    setState(() => _visible = show);
  }

  Future<void> _onEnable() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final FcmService service = ref.read(fcmServiceProvider);
      // Best-effort permission request via the existing FCM pipeline. The
      // service short-circuits when firebase isn't enabled.
      await service.registerToken();
    } finally {
      // Whether the user granted or denied, we don't nag again.
      await ref.read(pushPermissionBannerProvider).markShown();
      if (mounted) {
        setState(() {
          _visible = false;
          _requesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_visible != true) {
      return const SizedBox.shrink(
        key: ValueKey<String>('push-permission-banner-hidden'),
      );
    }
    return Padding(
      key: const ValueKey<String>('push-permission-banner'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: AppBanner(
        intent: AppIntent.info,
        title: context.t('push.permissionBannerTitle'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(context.t('push.permissionBannerBody')),
            const SizedBox(height: 8),
            AppButton(
              key: const Key('pushPermissionBanner.enable'),
              label: context.t('push.permissionBannerEnable'),
              variant: AppButtonVariant.gold,
              size: AppButtonSize.small,
              fullWidth: false,
              loading: _requesting,
              onPressed: _onEnable,
            ),
          ],
        ),
      ),
    );
  }
}

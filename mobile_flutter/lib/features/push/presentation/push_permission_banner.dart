import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/env.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/push/fcm_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/fcm_lifecycle_provider.dart';
import '../providers/push_permission_provider.dart';

/// Which affordance the banner is currently rendering.
enum _BannerVariant {
  /// Permission can still be requested — offer "Enable" (with priming).
  prompt,

  /// Permission is permanently denied — the OS dialog is gone, so the only
  /// recovery is the system settings app (spec section 10.5).
  deniedRecovery,
}

/// Inline banner that surfaces the "Enable notifications" gallery affordance
/// (section I6) at the top of the home screen.
///
/// Two responsibilities, selected by the live OS permission status:
///   * [_BannerVariant.prompt] — notifications can still be requested. Tapping
///     "Enable" runs a priming step (explains the value) BEFORE the OS dialog,
///     then registers the token. Only a confirmed grant (or an explicit
///     dismiss) marks the banner shown — a denial flips it to the recovery
///     variant so the user is not silently nagged-then-abandoned.
///   * [_BannerVariant.deniedRecovery] — permission is permanently denied. The
///     banner switches to [AppIntent.warning] and offers an "Open settings"
///     CTA via `openAppSettings()`.
///
/// Renders nothing when notifications are already granted, when the banner has
/// been dismissed/satisfied (`PushPermissionBanner.shouldShow() == false`), or
/// when `Env.firebaseEnabled == false` (Expo Go parity / dev rigs without a
/// google-services.json).
class PushPermissionBannerWidget extends ConsumerStatefulWidget {
  const PushPermissionBannerWidget({super.key});

  @override
  ConsumerState<PushPermissionBannerWidget> createState() =>
      _PushPermissionBannerWidgetState();
}

class _PushPermissionBannerWidgetState
    extends ConsumerState<PushPermissionBannerWidget> {
  /// Tri-state visibility:
  ///   - `null`  → SharedPreferences / permission status hasn't resolved yet.
  ///   - `true`  → render the banner ([_variant] picks which copy).
  ///   - `false` → already granted / dismissed — collapse for the session.
  bool? _visible;
  _BannerVariant _variant = _BannerVariant.prompt;
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
    final FcmService service = ref.read(fcmServiceProvider);
    final PushPermissionStatus status = await service.permissionStatus();
    if (!mounted) return;

    // Already authorized → never offer "Enable".
    if (status == PushPermissionStatus.granted) {
      setState(() => _visible = false);
      return;
    }

    final bool show = await ref.read(pushPermissionBannerProvider).shouldShow();
    if (!mounted) return;
    setState(() {
      _variant = status == PushPermissionStatus.permanentlyDenied
          ? _BannerVariant.deniedRecovery
          : _BannerVariant.prompt;
      _visible = show;
    });
  }

  /// Prompt variant: prime the user, then fire the OS permission request.
  Future<void> _onEnable() async {
    if (_requesting) return;
    Haptics.light();

    // Priming step — explain the value BEFORE the OS dialog so a first-time
    // user understands the ask. Bail without prompting if they decline.
    final bool primed = await ref.read(confirmServiceProvider).confirm(
          context,
          title: context.t('push.priming.title'),
          body: context.t('push.priming.body'),
          confirmLabel: context.t('push.priming.confirm'),
          cancelLabel: context.t('common.cancel'),
        );
    if (!primed || !mounted) return;

    setState(() => _requesting = true);
    // The user passed priming and we're about to surface the OS dialog.
    Analytics.log(AppEvent.pushPermissionPrompted);
    final FcmService service = ref.read(fcmServiceProvider);
    // Capture the grant/deny result — registerToken() returns true ONLY on a
    // confirmed, server-registered grant. The fcmLifecycleProvider picks up
    // the freshly granted token via its normal lifecycle.
    final bool granted = await service.registerToken();
    Analytics.log(
      granted ? AppEvent.pushPermissionGranted : AppEvent.pushPermissionDenied,
    );
    if (!mounted) {
      _requesting = false;
      return;
    }

    if (granted) {
      Haptics.medium();
      // Confirmed grant — mark shown so we never nag again, then collapse.
      await ref.read(pushPermissionBannerProvider).markShown();
      if (!mounted) return;
      setState(() {
        _visible = false;
        _requesting = false;
      });
      return;
    }

    // Denied: do NOT markShown — flip to the recovery variant so the user can
    // still reach system settings.
    setState(() {
      _variant = _BannerVariant.deniedRecovery;
      _requesting = false;
    });
  }

  /// Denied-recovery variant: send the user to the OS settings page.
  Future<void> _onOpenSettings() async {
    Haptics.light();
    await openAppSettings();
  }

  /// Explicit dismiss (the AppBanner X). Honours "never nag again".
  Future<void> _onDismiss() async {
    Haptics.selection();
    await ref.read(pushPermissionBannerProvider).markShown();
    if (!mounted) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_visible != true) {
      return const SizedBox.shrink(
        key: ValueKey<String>('push-permission-banner-hidden'),
      );
    }
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final bool denied = _variant == _BannerVariant.deniedRecovery;

    return Padding(
      key: const ValueKey<String>('push-permission-banner'),
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
      child: AppBanner(
        intent: denied ? AppIntent.warning : AppIntent.info,
        title: context.t(
          denied ? 'push.permissionDeniedTitle' : 'push.permissionBannerTitle',
        ),
        onClose: _onDismiss,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.t(
                denied
                    ? 'push.permissionDeniedBody'
                    : 'push.permissionBannerBody',
              ),
            ),
            Gap(spacing.sm),
            AppButton(
              key: Key(
                denied
                    ? 'pushPermissionBanner.openSettings'
                    : 'pushPermissionBanner.enable',
              ),
              label: context.t(
                denied ? 'push.openSettings' : 'push.permissionBannerEnable',
              ),
              variant: AppButtonVariant.gold,
              size: AppButtonSize.small,
              fullWidth: false,
              loading: _requesting,
              onPressed: denied ? _onOpenSettings : _onEnable,
            ),
          ],
        ),
      ),
    );
  }
}

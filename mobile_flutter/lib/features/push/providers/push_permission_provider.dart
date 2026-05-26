import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-shot banner state for the FCM permission-denied case (spec section
/// 10.5). After [markShown] is called once, [shouldShow] returns false on
/// every subsequent visit - we never nag.
class PushPermissionBanner {
  const PushPermissionBanner();
  static const String _key = 'push_perm_denied_shown';

  Future<bool> shouldShow() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  Future<void> markShown() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Test seam: re-arms the banner so re-running shouldShow() yields true.
  Future<void> resetForTest() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final Provider<PushPermissionBanner> pushPermissionBannerProvider =
    Provider<PushPermissionBanner>((Ref<PushPermissionBanner> ref) {
  return const PushPermissionBanner();
});

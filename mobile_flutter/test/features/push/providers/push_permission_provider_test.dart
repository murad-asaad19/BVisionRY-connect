import 'package:connect_mobile/features/push/providers/push_permission_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('shouldShow returns true on first denial only', () async {
    const PushPermissionBanner banner = PushPermissionBanner();
    expect(await banner.shouldShow(), isTrue);
    await banner.markShown();
    expect(await banner.shouldShow(), isFalse);
  });

  test('resetForTest re-arms the banner', () async {
    const PushPermissionBanner banner = PushPermissionBanner();
    await banner.markShown();
    expect(await banner.shouldShow(), isFalse);
    await banner.resetForTest();
    expect(await banner.shouldShow(), isTrue);
  });

  test('markShown is idempotent (multiple calls keep it suppressed)',
      () async {
    const PushPermissionBanner banner = PushPermissionBanner();
    await banner.markShown();
    await banner.markShown();
    expect(await banner.shouldShow(), isFalse);
  });
}

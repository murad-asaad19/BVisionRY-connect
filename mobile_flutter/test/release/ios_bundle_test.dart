import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS pbxproj uses bundle id com.bvisionry.connect', () {
    final pbxproj =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbxproj, contains('PRODUCT_BUNDLE_IDENTIFIER = com.bvisionry.connect;'));
    expect(pbxproj, isNot(contains('com.bvisionry.connect_mobile')));
    expect(pbxproj, isNot(contains('com.bvisionry.connectMobile;')));
  });

  test('Info.plist declares CFBundleURLSchemes connect-mobile + display name',
      () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>connect-mobile</string>'));
    expect(plist, contains('<string>Connect</string>'));
    expect(plist, contains('NSMicrophoneUsageDescription'));
    expect(plist, contains('NSPhotoLibraryUsageDescription'));
  });

  test('Runner.entitlements declares applinks + push capability', () {
    final ent = File('ios/Runner/Runner.entitlements').readAsStringSync();
    expect(ent, contains('com.apple.developer.associated-domains'));
    expect(ent, contains('applinks:connect.bvisionry.com'));
    expect(ent, contains('applinks:www.connect.bvisionry.com'));
    expect(ent, contains('aps-environment'));
    expect(ent, isNot(contains('DOMAIN_PLACEHOLDER')));
  });

  test('ExportOptions.plist is committed for App Store archive', () {
    final f = File('ios/ExportOptions.plist');
    expect(f.existsSync(), isTrue, reason: 'ios/ExportOptions.plist missing');
    final t = f.readAsStringSync();
    expect(t, contains('<key>method</key>'));
    expect(t, contains('app-store'));
  });
}

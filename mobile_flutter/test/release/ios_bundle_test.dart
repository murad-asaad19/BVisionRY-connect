import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS pbxproj uses bundle id com.bvisionry.connect', () {
    final pbxproj =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(
      pbxproj,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.bvisionry.connect;'),
    );
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

  test('Info.plist declares export-compliance (non-exempt encryption = false)',
      () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    // App ships only standard/exempt (HTTPS) encryption; declaring this
    // skips the manual export-compliance prompt on every App Store upload.
    expect(plist, contains('ITSAppUsesNonExemptEncryption'));
  });

  test('Runner.entitlements declares applinks + push capability', () {
    final ent = File('ios/Runner/Runner.entitlements').readAsStringSync();
    expect(ent, contains('com.apple.developer.associated-domains'));
    expect(ent, contains('applinks:connect.bvisionry.com'));
    expect(ent, contains('applinks:www.connect.bvisionry.com'));
    expect(ent, contains('aps-environment'));
    expect(ent, isNot(contains('DOMAIN_PLACEHOLDER')));
  });

  test('pbxproj wires Runner.entitlements into every Runner build config', () {
    // The entitlements file is inert unless CODE_SIGN_ENTITLEMENTS points at
    // it in the build settings — otherwise push + universal links silently do
    // not ship. The three Runner app-target configs (Debug/Release/Profile)
    // each carry INFOPLIST_FILE = Runner/Info.plist, so the entitlements key
    // must appear at least that many times.
    final pbxproj =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final entitlementsRefs = 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
        .allMatches(pbxproj)
        .length;
    final infoPlistRefs =
        'INFOPLIST_FILE = Runner/Info.plist;'.allMatches(pbxproj).length;
    expect(infoPlistRefs, 3, reason: 'expected 3 Runner app-target configs');
    expect(
      entitlementsRefs,
      greaterThanOrEqualTo(infoPlistRefs),
      reason: 'every Runner config must reference Runner.entitlements',
    );
  });

  test('ExportOptions.plist is committed for App Store archive', () {
    final f = File('ios/ExportOptions.plist');
    expect(f.existsSync(), isTrue, reason: 'ios/ExportOptions.plist missing');
    final t = f.readAsStringSync();
    expect(t, contains('<key>method</key>'));
    expect(t, contains('app-store'));
  });
}

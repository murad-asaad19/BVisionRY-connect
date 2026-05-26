import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android applicationId is com.bvisionry.connect', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.bvisionry.connect"'));
    expect(gradle, contains('namespace = "com.bvisionry.connect"'));
    expect(gradle, isNot(contains('com.bvisionry.connect_mobile')));
    expect(gradle, contains('signingConfigs'));
  });

  test('AndroidManifest declares deep-link intent-filters + FCM meta', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:scheme="connect-mobile"'));
    expect(manifest, contains('android:host="connect.bvisionry.com"'));
    expect(manifest, contains('android:pathPrefix="/p/"'));
    expect(manifest, contains('android:autoVerify="true"'));
    expect(
      manifest,
      contains('com.google.firebase.messaging.default_notification_icon'),
    );
    expect(manifest, isNot(contains('DOMAIN_PLACEHOLDER')));
  });

  test('key.properties.example committed for release signing', () {
    final f = File('android/key.properties.example');
    expect(f.existsSync(), isTrue, reason: 'android/key.properties.example missing');
  });
}

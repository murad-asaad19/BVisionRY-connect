import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as gfb;

/// Per-suite test config — Flutter discovers this file automatically.
///
/// Two responsibilities, both invisible to the tests themselves:
///
/// 1. Pre-load fonts via `golden_toolkit.loadAppFonts()` so widget render
///    dimensions are deterministic.
/// 2. Stop GoogleFonts from attempting an HTTP fetch — instead, claim a
///    synthetic asset manifest of `<Family>-<Variant>.ttf` paths and have
///    our `flutter/assets` mock handler serve the bundled Roboto bytes
///    whenever any of those keys is requested. Every other asset key
///    (locale JSONs, etc.) falls through to the standard test binding
///    behaviour by reading from `UNIT_TEST_ASSETS` on disk.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  _wireGoogleFontsToBundledRoboto();
  return GoldenToolkit.runWithConfiguration(
    () async => testMain(),
    config: GoldenToolkitConfiguration(
      enableRealShadows: false,
      skipGoldenAssertion: () => false,
    ),
  );
}

void _wireGoogleFontsToBundledRoboto() {
  // Roboto-Regular.ttf is shipped as a real asset by the `golden_toolkit`
  // dev dep. We read it once from disk and reuse the bytes for every
  // synthetic font asset key.
  const variants = <String>['Regular', 'Medium', 'SemiBold', 'Bold'];
  final fontAssetPaths = <String>{
    for (final family in <String>['Dosis', 'Inter'])
      for (final variant in variants) 'assets/fonts/$family-$variant.ttf',
  };

  gfb.assetManifest = _StaticAssetManifest(fontAssetPaths.toList());
  GoogleFonts.config.allowRuntimeFetching = false;

  // The standard flutter_test binding installs a handler on `flutter/assets`
  // that resolves keys against the `UNIT_TEST_ASSETS` directory. Override
  // it with one that:
  //   • Returns Roboto bytes for our synthetic font keys.
  //   • Replicates the binding's on-disk read for any other key (so the
  //     locale JSONs and real package assets keep loading).
  final assetFolder = Platform.environment['UNIT_TEST_ASSETS'];
  final appName = Platform.environment['APP_NAME'];
  if (assetFolder == null) return;

  final robotoBytes = _loadFromDisk(
    assetFolder,
    appName,
    'packages/golden_toolkit/fonts/Roboto-Regular.ttf',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) return null;
    final key = utf8.decode(
      message.buffer.asUint8List(
        message.offsetInBytes,
        message.lengthInBytes,
      ),
    );
    if (fontAssetPaths.contains(key)) {
      return robotoBytes;
    }
    return _loadFromDisk(assetFolder, appName, key);
  });
}

ByteData? _loadFromDisk(String assetFolder, String? appName, String key) {
  var file = File('$assetFolder${Platform.pathSeparator}$key');
  if (!file.existsSync() && appName != null) {
    final prefix = 'packages/$appName/';
    if (key.startsWith(prefix)) {
      final stripped = key.replaceFirst(prefix, '');
      file = File('$assetFolder${Platform.pathSeparator}$stripped');
    }
  }
  if (!file.existsSync()) return null;
  final bytes = Uint8List.fromList(file.readAsBytesSync());
  return ByteData.view(bytes.buffer);
}

class _StaticAssetManifest implements AssetManifest {
  _StaticAssetManifest(this._assets);
  final List<String> _assets;

  @override
  List<String> listAssets() => _assets;

  @override
  List<AssetMetadata> getAssetVariants(String key) => const [];
}

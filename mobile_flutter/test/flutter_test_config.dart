import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as gfb;

/// Per-suite test config — Flutter discovers this file automatically.
///
/// We patch GoogleFonts so it resolves every font via a bundled Roboto TTF
/// (already shipped by `golden_toolkit` as a dev dep). Without this, every
/// widget test that touches our theme's typography would fail offline
/// because GoogleFonts attempts an HTTP fetch by default.
///
/// Strategy: feed GoogleFonts a custom AssetManifest that claims our app
/// already bundles Dosis-* and Inter-* asset files. When GoogleFonts then
/// calls `rootBundle.load(<asset>)`, we have our mock binary messenger
/// return the Roboto bytes for any of those asset paths.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  await _wireGoogleFontsToBundledRoboto();
  return GoldenToolkit.runWithConfiguration(
    () async => testMain(),
    config: GoldenToolkitConfiguration(
      enableRealShadows: false,
      skipGoldenAssertion: () => false,
    ),
  );
}

Future<void> _wireGoogleFontsToBundledRoboto() async {
  final ByteData fontData;
  try {
    fontData = await rootBundle.load(
      'packages/golden_toolkit/fonts/Roboto-Regular.ttf',
    );
  } catch (_) {
    return;
  }
  final fontBytes = Uint8List.view(fontData.buffer);

  // Reachable filename variants used by our typography. Each `<Family>-<Variant>.ttf`
  // claim makes GoogleFonts' asset lookup succeed without any HTTP fetch.
  const variants = <String>[
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
  ];
  final assetPaths = <String>[
    for (final family in <String>['Dosis', 'Inter'])
      for (final variant in variants) 'assets/fonts/$family-$variant.ttf',
  ];

  gfb.assetManifest = _StaticAssetManifest(assetPaths);
  // Block runtime fetching now that the asset path will resolve. This also
  // turns any unexpected miss into a fast, loud failure rather than a hang.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Intercept `rootBundle.load` for those asset paths — we don't actually
  // ship them, but the mock returns the Roboto bytes so the engine has real
  // glyph data to render.
  ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (ByteData? message) async {
      final key = utf8FromByteData(message);
      if (key == null) return null;
      for (final path in assetPaths) {
        if (key == path) {
          return ByteData.view(fontBytes.buffer);
        }
      }
      return null;
    },
  );
}

String? utf8FromByteData(ByteData? data) {
  if (data == null) return null;
  final bytes = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  try {
    return const Utf8Decoder().convert(bytes);
  } catch (_) {
    return null;
  }
}

class _StaticAssetManifest implements AssetManifest {
  _StaticAssetManifest(this._assets);
  final List<String> _assets;

  @override
  List<String> listAssets() => _assets;

  @override
  List<AssetMetadata> getAssetVariants(String key) => const [];
}

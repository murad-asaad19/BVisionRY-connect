import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme installs platform-aware page transition builders', () {
    final theme = buildAppTheme(Brightness.light);
    expect(
      theme.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<FadeUpwardsPageTransitionsBuilder>(),
    );
    expect(
      theme.pageTransitionsTheme.builders[TargetPlatform.iOS],
      isA<CupertinoPageTransitionsBuilder>(),
    );
  });
}

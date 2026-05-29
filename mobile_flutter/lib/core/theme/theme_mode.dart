import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active [ThemeMode] for the app (system / light / dark).
///
/// Defaults to following the OS setting. The settings screen exposes a
/// toggle that updates this provider and persists the choice; `ConnectApp`
/// watches it to drive `MaterialApp.themeMode`.
final StateProvider<ThemeMode> themeModeProvider =
    StateProvider<ThemeMode>((Ref<ThemeMode> ref) => ThemeMode.system);

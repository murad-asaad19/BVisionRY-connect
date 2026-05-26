import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/language_service.dart';

// Convenience re-exports — pulling these via the barrel lets a Phase 13
// settings screen import a single file instead of three deep-feature paths.
export '../push/providers/notification_prefs_provider.dart'
    show
        notificationPrefsServiceProvider,
        notificationPrefsProvider,
        notificationPrefsMatrixProvider,
        NotificationPrefsMatrix;
export '../telemetry/stub_telemetry_store.dart'
    show TelemetryState, TelemetryStore, telemetryStoreProvider;
export 'data/language_service.dart';
export 'data/settings_service.dart' show SettingsService, settingsServiceProvider;

/// The configured [LanguageService] singleton. Override in tests via
/// `languageServiceProvider.overrideWithValue(...)`.
final Provider<LanguageService> languageServiceProvider =
    Provider<LanguageService>((Ref<LanguageService> ref) => LanguageService());

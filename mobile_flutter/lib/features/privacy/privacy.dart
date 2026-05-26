/// Feature barrel for the Privacy slice.
///
/// Downstream phases (4 Profile / 6 Intros / 7 Chat / 13 Settings) import
/// from `package:connect_mobile/features/privacy/privacy.dart` to pick up
/// the public surface — `BlockButton`, `showReportSheet`, the two enums,
/// the providers, and the service handle — without reaching into the
/// per-file paths inside the feature.
library;

export 'data/privacy_service.dart' show PrivacyService, privacyServiceProvider;
export 'domain/blocked_user.dart';
export 'domain/report_reason.dart';
export 'domain/report_target_type.dart';
export 'presentation/block_button.dart';
export 'presentation/blocked_users_screen.dart';
export 'presentation/report_sheet.dart' show showReportSheet;
export 'providers/blocks_provider.dart';

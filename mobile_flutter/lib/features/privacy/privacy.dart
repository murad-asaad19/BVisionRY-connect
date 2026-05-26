/// Feature barrel for the Privacy slice.
///
/// Downstream phases (4 Profile / 6 Intros / 7 Chat / 13 Settings) import
/// from `package:connect_mobile/features/privacy/privacy.dart` to pick up
/// the public surface — `BlockButton`, `showReportSheet`, the two enums,
/// the providers, and the service handle — without reaching into the
/// per-file paths inside the feature.
///
/// ## Cross-phase integration matrix
///
/// | Phase | Surface | Touchpoint |
/// |---|---|---|
/// | 04 Profile | `profile_screen.dart` more-menu | `BlockButton(userId, name, handle)` row + a `showReportSheet(ctx, ReportTargetType.profile, userId)` item. |
/// | 06 Intros | `intro_detail_screen.dart` overflow | "Report intro" → `showReportSheet(ctx, ReportTargetType.intro, intro.id)`. |
/// | 07 Chat | `message_bubble.dart` long-press menu | "Report message" → `showReportSheet(ctx, ReportTargetType.message, msg.id, quotedMessageId: msg.id, quotedBodyPreview: msg.body)`. |
/// | 13 Settings | `settings_screen.dart` privacy section | `SettingsRow(label: settings.blockedUsers, onTap: () => context.go(Routes.settingsBlocked))`. |
///
/// Each downstream phase plan owns the integration. This file is the
/// import surface — adding/removing exports here is a breaking change
/// the consuming phases must follow.
library;

export 'data/privacy_service.dart' show PrivacyService, privacyServiceProvider;
export 'domain/blocked_user.dart';
export 'domain/report_reason.dart';
export 'domain/report_target_type.dart';
export 'presentation/block_button.dart';
export 'presentation/blocked_users_screen.dart';
export 'presentation/report_sheet.dart' show showReportSheet;
export 'providers/blocks_provider.dart';

import 'package:flutter/widgets.dart';

import '../i18n/i18n.dart';
import 'app_exception.dart';

/// Resolves any error thrown by the data layer into localized, user-facing
/// copy.
///
/// Every service funnels failures through [mapPostgrestError] /
/// [mapAuthError] into a typed [AppException] carrying an `i18nKey`; anything
/// else falls back to the generic message. UI code must NEVER render
/// `error.toString()` directly (it leaks `RuntimeType(i18n.key)` diagnostic
/// strings) — call this instead.
String messageForError(BuildContext context, Object error) {
  if (error is AppException) return context.t(error.i18nKey);
  return context.t('errors.generic');
}

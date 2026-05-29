import 'package:flutter/widgets.dart';

import '../../../core/i18n/i18n.dart';

/// Roles that have a localized label under `discovery.roles.*` in the i18n
/// bundle. Any other server role falls back to a capitalized raw string.
const Set<String> _kLocalizedRoles = <String>{
  'founder',
  'leader',
  'builder',
  'investor',
};

/// Resolves a server `primary_role` string to its localized display label.
///
/// Discovery surfaces (match cards, search rows, network carousel) get the
/// role from the RPC as a lower-case token (e.g. `founder`). Known tokens
/// resolve via `discovery.roles.*`; unknown ones (the server may add roles
/// the bundle hasn't caught up with) fall back to a capitalized raw value so
/// the UI never leaks a dotted i18n key.
String roleLabel(BuildContext context, String role) {
  if (role.isEmpty) return role;
  if (_kLocalizedRoles.contains(role)) {
    return context.t('discovery.roles.$role');
  }
  return role[0].toUpperCase() + role.substring(1);
}

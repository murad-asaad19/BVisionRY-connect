import 'package:flutter/widgets.dart';

/// Phase 15 — accessibility helpers for icon-only widgets.
///
/// Maps Lucide icon names to human-readable Semantics labels. Used by
/// icon-only buttons and decorative badges (verified, mute, etc.) so
/// screen readers announce a meaningful label.
String semanticIconLabel(String iconName) {
  return switch (iconName) {
    'Inbox' => 'inbox',
    'Send' => 'send',
    'Mic' => 'record voice',
    'Pause' => 'pause',
    'Play' => 'play',
    'Trash2' => 'delete',
    'Edit' => 'edit',
    'BadgeCheck' => 'verified',
    'Bell' => 'notifications',
    'BellOff' => 'mute',
    'X' => 'close',
    'Check' => 'confirm',
    'Settings' => 'settings',
    'Home' => 'home',
    _ => iconName.toLowerCase(),
  };
}

/// Wraps a child in a Semantics node with a label derived from
/// [iconName].
class IconSemantics extends StatelessWidget {
  const IconSemantics({
    super.key,
    required this.iconName,
    required this.child,
  });

  final String iconName;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(label: semanticIconLabel(iconName), child: child);
}

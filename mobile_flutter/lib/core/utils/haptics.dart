import 'package:flutter/services.dart';

/// Centralized tactile feedback for key interactions.
///
/// Wrapping [HapticFeedback] in one place keeps the app's "feel" consistent
/// and tunable (and easy to disable globally for tests / accessibility).
/// Apply on meaningful actions only — sends, confirmations, toggles, and the
/// signature intro-accepted moment — never on every tap.
abstract final class Haptics {
  /// Light tick — selection changes, toggles, tab switches.
  static void selection() => HapticFeedback.selectionClick();

  /// Light impact — primary button presses, sending a message.
  static void light() => HapticFeedback.lightImpact();

  /// Medium impact — confirmations, completing a step.
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy impact — celebratory / significant moments (intro accepted).
  static void heavy() => HapticFeedback.heavyImpact();

  /// Error / rejection buzz.
  static void error() => HapticFeedback.vibrate();
}

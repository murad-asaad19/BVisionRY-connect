import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../env.dart';

/// Stable, snake_case product-event catalog for the core-loop funnel.
///
/// Each value's [wire] string is the exact event name shipped to Firebase
/// Analytics. These names are an analytics contract — once a dashboard /
/// funnel references one, renaming it silently breaks reporting, so treat
/// them as append-only and do NOT repurpose an existing name.
///
/// Param names live alongside the call sites (see [Analytics]); both event
/// and param names stay snake_case to match GA4 conventions. Never log PII
/// (names, handles, emails, free-text notes, message bodies).
enum AppEvent {
  // ── Onboarding wizard ──────────────────────────────────────────────
  /// First onboarding step (Goal) reached for a fresh profile.
  onboardingStarted('onboarding_started'),

  /// One wizard step completed / advanced. Param: `step` (goal|roles|bio).
  onboardingStepCompleted('onboarding_step_completed'),

  /// `finish_onboarding` succeeded — the user is now in the app proper.
  onboardingCompleted('onboarding_completed'),

  // ── Discovery ──────────────────────────────────────────────────────
  /// A daily-match card was tapped through to a profile.
  /// Param: `featured` (bool).
  matchCardOpened('match_card_opened'),

  // ── Intros ─────────────────────────────────────────────────────────
  /// The intro composer sheet was opened. Param: `via_warm` (bool).
  introComposeOpened('intro_compose_opened'),

  /// An intro was sent successfully. Param: `via_warm` (bool).
  introSent('intro_sent'),

  /// An intro send attempt failed. Param: `via_warm` (bool).
  introSendFailed('intro_send_failed'),

  /// The recipient accepted an inbound intro (the app's signature moment).
  introAccepted('intro_accepted'),

  /// The recipient declined an inbound intro.
  introDeclined('intro_declined'),

  // ── Chat ───────────────────────────────────────────────────────────
  /// A conversation thread was opened.
  conversationOpened('conversation_opened'),

  // ── Meetings ───────────────────────────────────────────────────────
  /// A meeting proposal was sent by the proposer.
  meetingProposed('meeting_proposed'),

  /// A proposed meeting slot was confirmed by the recipient.
  meetingConfirmed('meeting_confirmed'),

  // ── Profile ────────────────────────────────────────────────────────
  /// The profile edit screen was opened.
  profileEditOpened('profile_edit_opened'),

  /// The profile edit form was saved successfully.
  profileSaved('profile_saved'),

  // ── Push ───────────────────────────────────────────────────────────
  /// The OS push-permission prompt was surfaced to the user.
  pushPermissionPrompted('push_permission_prompted'),

  /// The user granted push permission.
  pushPermissionGranted('push_permission_granted'),

  /// The user denied push permission.
  pushPermissionDenied('push_permission_denied');

  const AppEvent(this.wire);

  /// The on-the-wire snake_case event name sent to Firebase Analytics.
  final String wire;
}

/// Thin, typed product-analytics facade over Firebase Analytics.
///
/// Design mirrors the existing [Telemetry] / `sentry` facades: a single
/// static surface that is safe to call from any code path. Logging is a
/// no-op when `Env.firebaseEnabled` is false (web / Expo-Go-parity / dev
/// rigs without `google-services` config) — the same build gate the rest
/// of the telemetry layer uses.
///
/// We deliberately do NOT re-check the user's analytics-consent flag here:
/// consent is already enforced at the SDK level via
/// `FirebaseAnalytics.setAnalyticsCollectionEnabled`, which
/// `TelemetryNotifier` applies live the moment the toggle flips
/// (see `firebase_telemetry.dart`). A disabled-collection SDK drops
/// `logEvent` calls itself, so double-gating here would be redundant and
/// could drift from the single source of truth.
abstract final class Analytics {
  /// Lazily-resolved Firebase Analytics handle. Only touched when
  /// `Env.firebaseEnabled` is true, so the plugin singleton is never
  /// accessed on platforms where Firebase isn't initialised.
  static FirebaseAnalytics? _instance;

  static FirebaseAnalytics get _analytics =>
      _instance ??= FirebaseAnalytics.instance;

  /// Test seam — inject a fake/mocked [FirebaseAnalytics] so widget tests
  /// can assert events without a live Firebase app. Pass `null` to reset.
  @visibleForTesting
  static set debugInstance(FirebaseAnalytics? value) => _instance = value;

  /// Logs [event] with optional snake_case [params].
  ///
  /// No-op when Firebase is disabled in this build. Fire-and-forget: the
  /// returned future from the SDK is intentionally not awaited so call
  /// sites never block UI on telemetry, and any failure is swallowed
  /// (analytics must never break a user flow). In debug builds a disabled
  /// log still prints so the call is traceable locally.
  static void log(AppEvent event, [Map<String, Object>? params]) {
    if (!Env.firebaseEnabled) {
      if (kDebugMode) {
        debugPrint('analytics.log ${event.wire} ${params ?? const {}}');
      }
      return;
    }
    unawaited(
      _analytics
          .logEvent(name: event.wire, parameters: params)
          .catchError((Object _) {
        // Telemetry is best-effort — never surface a logging failure.
      }),
    );
  }
}

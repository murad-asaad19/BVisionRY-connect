import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Distinguishes which auth flow raised the error — controls the fallback
/// i18n key when no specific message pattern matches.
enum AuthMode { signIn, signUp }

/// Maps an auth-flow error onto the i18n key the UI should render.
///
/// Mirrors the RN `mobile/src/features/auth/services/errorMap.ts` behaviour
/// 1:1: network sniffs first, then well-known GoTrue message substrings,
/// then a mode-aware fallback.
String mapAuthError(Object? err, AuthMode mode) {
  if (_isNetwork(err)) return 'auth.errors.network';
  final msg = _extractMessage(err).toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return 'auth.errors.invalidCredentials';
  }
  if (msg.contains('email not confirmed')) {
    return 'auth.errors.emailNotConfirmed';
  }
  if (msg.contains('rate limit') ||
      msg.contains('too many requests') ||
      msg.contains('over_email_send_rate_limit') ||
      msg.contains('over_request_rate_limit')) {
    return 'auth.errors.rateLimited';
  }
  return mode == AuthMode.signUp
      ? 'auth.errors.signUpFailed'
      : 'auth.errors.signInFailed';
}

bool _isNetwork(Object? err) {
  if (err == null) return false;
  if (err is SocketException) return true;
  if (err is TimeoutException) return true;
  if (err is HttpException) return true;
  if (err is FunctionException && err.status == 0) {
    // Functions transport-level errors carry status==0 when no response.
    return true;
  }
  final msg = _extractMessage(err).toLowerCase();
  return msg.contains('failed to fetch') ||
      msg.contains('network request failed') ||
      msg.contains('networkerror') ||
      msg.contains('clientexception with socketexception');
}

String _extractMessage(Object? err) {
  if (err == null) return '';
  if (err is AuthException) return err.message;
  if (err is FunctionException) {
    final d = err.details;
    if (d is Map && d['error'] is String) return d['error'] as String;
    return err.reasonPhrase ?? '';
  }
  if (err is String) return err;
  if (err is Error) return err.toString();
  if (err is Exception) return err.toString();
  try {
    final dyn = err as dynamic;
    final m = dyn.message;
    if (m is String) return m;
  } catch (_) {
    // best-effort.
  }
  return err.toString();
}

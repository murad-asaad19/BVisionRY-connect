import 'dart:async';
import 'dart:io';

import 'package:connect_mobile/features/auth/data/auth_error_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('SocketException → auth.errors.network', () {
    expect(
      mapAuthError(const SocketException('boom'), AuthMode.signIn),
      'auth.errors.network',
    );
  });
  test('TimeoutException → auth.errors.network', () {
    expect(
      mapAuthError(TimeoutException('boom'), AuthMode.signIn),
      'auth.errors.network',
    );
  });
  test('Invalid login credentials → invalidCredentials', () {
    const ex = AuthException('Invalid login credentials');
    expect(mapAuthError(ex, AuthMode.signIn), 'auth.errors.invalidCredentials');
  });
  test('Email not confirmed → emailNotConfirmed', () {
    expect(
      mapAuthError(
        const AuthException('Email not confirmed'),
        AuthMode.signIn,
      ),
      'auth.errors.emailNotConfirmed',
    );
  });
  test('rate limit phrasings → rateLimited', () {
    for (final m in const <String>[
      'Email rate limit exceeded',
      'over_email_send_rate_limit',
      'over_request_rate_limit',
      'Too many requests',
    ]) {
      expect(
        mapAuthError(AuthException(m),
            AuthMode.signIn,), // ignore: prefer_const_constructors
        'auth.errors.rateLimited',
        reason: m,
      );
    }
  });
  test('signUp fallback → signUpFailed', () {
    expect(
      mapAuthError(const AuthException('weird unknown'), AuthMode.signUp),
      'auth.errors.signUpFailed',
    );
  });
  test('signIn fallback → signInFailed', () {
    expect(
      mapAuthError(const AuthException('weird unknown'), AuthMode.signIn),
      'auth.errors.signInFailed',
    );
  });
  test('string error supported', () {
    expect(
      mapAuthError('failed to fetch', AuthMode.signIn),
      'auth.errors.network',
    );
  });
  test('null → fallback', () {
    expect(mapAuthError(null, AuthMode.signIn), 'auth.errors.signInFailed');
  });
}

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../env.dart';

bool _initialized = false;
Future<bool>? _inflight;

/// Initialises Firebase on the calling platform when [Env.firebaseEnabled].
///
/// Returns `true` once the default app is ready, `false` if disabled by env
/// or unsupported on this platform (web - we ship FCM mobile-only).
///
/// Idempotent: safe to call from `app.dart`, the lifecycle provider, and
/// background-tap handlers without re-initialising.
Future<bool> ensureFirebaseInitialized() {
  if (!Env.firebaseEnabled) return Future<bool>.value(false);
  if (_initialized) return Future<bool>.value(true);
  if (kIsWeb) return Future<bool>.value(false);
  return _inflight ??= _init();
}

Future<bool> _init() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    _initialized = true;
    return true;
  } catch (e, st) {
    debugPrint('[firebase_init] failed: $e\n$st');
    _inflight = null;
    return false;
  }
}

@visibleForTesting
void resetFirebaseInitForTest() {
  _initialized = false;
  _inflight = null;
}

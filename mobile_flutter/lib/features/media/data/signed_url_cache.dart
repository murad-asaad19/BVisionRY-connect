import 'package:flutter/foundation.dart';

typedef SignedUrlFetcher = Future<String> Function(String path);

@immutable
class _CacheEntry {
  const _CacheEntry(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
}

/// TTL-aware cache for chat-media signed URLs.
///
/// Chat-media is a private bucket; every image / voice bubble has to fetch
/// a signed URL before it can hit the network. The cache eliminates the
/// per-render fetch by holding URLs for [ttl] minus a [safetyWindow] so
/// callers never get a URL that expires while in flight.
///
/// Not thread-safe across isolates, but Flutter UI calls happen on the
/// main isolate so a plain `Map` is enough.
class SignedUrlCache {
  SignedUrlCache({
    required this.ttl,
    required this.safetyWindow,
    required this.fetcher,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final Duration ttl;
  final Duration safetyWindow;
  final SignedUrlFetcher fetcher;
  final DateTime Function() _now;
  final Map<String, _CacheEntry> _entries = <String, _CacheEntry>{};

  /// Returns a cached URL if still valid, otherwise fetches a fresh one
  /// and caches it for `ttl - safetyWindow`.
  Future<String> get(String path) async {
    final entry = _entries[path];
    final now = _now();
    if (entry != null && entry.expiresAt.isAfter(now)) {
      return entry.url;
    }
    final fresh = await fetcher(path);
    _entries[path] = _CacheEntry(fresh, now.add(ttl - safetyWindow));
    return fresh;
  }

  /// Drops a specific path — call after an upload completes if you want
  /// to force the next read to pick up a freshly-signed URL.
  void invalidate(String path) => _entries.remove(path);

  /// Clears everything (e.g. on sign-out).
  void clear() => _entries.clear();
}

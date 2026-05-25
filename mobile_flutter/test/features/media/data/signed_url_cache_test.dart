import 'package:connect_mobile/features/media/data/signed_url_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns cached URL within TTL', () async {
    var calls = 0;
    final cache = SignedUrlCache(
      ttl: const Duration(seconds: 60),
      safetyWindow: const Duration(seconds: 5),
      now: () => DateTime.utc(2026, 5, 25, 10),
      fetcher: (path) async {
        calls++;
        return 'https://signed/$path?token=$calls';
      },
    );
    final first = await cache.get('a/b/photo.jpg');
    final second = await cache.get('a/b/photo.jpg');
    expect(second, equals(first));
    expect(calls, 1);
  });

  test('refetches after expiry', () async {
    var calls = 0;
    var nowMs = DateTime.utc(2026, 5, 25, 10).millisecondsSinceEpoch;
    final cache = SignedUrlCache(
      ttl: const Duration(seconds: 60),
      safetyWindow: const Duration(seconds: 5),
      now: () => DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
      fetcher: (path) async {
        calls++;
        return 'https://signed/$path?token=$calls';
      },
    );
    await cache.get('a/b/photo.jpg');
    nowMs += const Duration(seconds: 56).inMilliseconds;
    await cache.get('a/b/photo.jpg');
    expect(calls, 2);
  });

  test('invalidate forces refetch', () async {
    var calls = 0;
    final cache = SignedUrlCache(
      ttl: const Duration(seconds: 60),
      safetyWindow: const Duration(seconds: 5),
      now: () => DateTime.utc(2026, 5, 25, 10),
      fetcher: (path) async {
        calls++;
        return 'https://signed/$path?token=$calls';
      },
    );
    await cache.get('a/b/photo.jpg');
    cache.invalidate('a/b/photo.jpg');
    await cache.get('a/b/photo.jpg');
    expect(calls, 2);
  });

  test('clear drops every entry', () async {
    var calls = 0;
    final cache = SignedUrlCache(
      ttl: const Duration(seconds: 60),
      safetyWindow: const Duration(seconds: 5),
      now: () => DateTime.utc(2026, 5, 25, 10),
      fetcher: (path) async {
        calls++;
        return 'https://signed/$path?token=$calls';
      },
    );
    await cache.get('a.jpg');
    await cache.get('b.jpg');
    cache.clear();
    await cache.get('a.jpg');
    expect(calls, 3);
  });
}

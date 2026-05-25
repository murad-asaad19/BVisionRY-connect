// AvatarUploadService — pick → crop → compress → upload → cache-bust pipeline.
//
// We split the device-side surface (picker/cropper/compressor) from the
// storage surface (upload + getPublicUrl + photo_url patch) so the pipeline
// can be unit-tested entirely in-memory.
import 'dart:typed_data';

import 'package:connect_mobile/features/profile/data/avatar_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSource implements AvatarSource {
  _FakeSource(this._bytes, {this.throwable});
  final Uint8List? _bytes;
  final Object? throwable;
  int calls = 0;

  @override
  Future<Uint8List?> pickAndCropSquareAvatar() async {
    calls++;
    if (throwable != null) {
      // ignore: only_throw_errors
      throw throwable!;
    }
    return _bytes;
  }
}

class _FakeStorage implements AvatarStorageGateway {
  String? capturedPath;
  Uint8List? capturedBytes;
  String? capturedContentType;
  bool? capturedUpsert;
  String? capturedPatchUserId;
  String? capturedPatchUrl;
  String publicUrl = 'https://cdn.example.com/avatars/u-1/avatar.jpg';
  Object? uploadThrowable;
  Object? patchThrowable;

  @override
  Future<void> uploadAvatar({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {
    capturedPath = path;
    capturedBytes = bytes;
    capturedContentType = contentType;
    capturedUpsert = upsert;
    if (uploadThrowable != null) {
      // ignore: only_throw_errors
      throw uploadThrowable!;
    }
  }

  @override
  String getPublicUrl(String path) => publicUrl;

  @override
  Future<void> patchPhotoUrl({
    required String userId,
    required String url,
  }) async {
    capturedPatchUserId = userId;
    capturedPatchUrl = url;
    if (patchThrowable != null) {
      // ignore: only_throw_errors
      throw patchThrowable!;
    }
  }
}

void main() {
  group('AvatarUploadService', () {
    test('happy path uploads bytes to {userId}/avatar.jpg + returns a cache-busted URL',
        () async {
      final _FakeSource src =
          _FakeSource(Uint8List.fromList(List<int>.filled(64 * 1024, 1)));
      final _FakeStorage storage = _FakeStorage();
      final AvatarUploadService svc = AvatarUploadService(
        source: src,
        storage: storage,
        userId: 'u-1',
      );

      final String? url = await svc.pickAndUpload();
      expect(url, isNotNull);
      expect(
        url!.startsWith('https://cdn.example.com/avatars/u-1/avatar.jpg?v='),
        isTrue,
      );
      expect(storage.capturedPath, 'u-1/avatar.jpg');
      expect(storage.capturedContentType, 'image/jpeg');
      expect(storage.capturedUpsert, isTrue);
      expect(storage.capturedPatchUserId, 'u-1');
      expect(storage.capturedPatchUrl, url);
    });

    test('returns null when the user cancels the picker', () async {
      final _FakeSource src = _FakeSource(null);
      final _FakeStorage storage = _FakeStorage();
      final AvatarUploadService svc = AvatarUploadService(
        source: src,
        storage: storage,
        userId: 'u-1',
      );
      expect(await svc.pickAndUpload(), isNull);
      expect(
        storage.capturedPath,
        isNull,
        reason: 'cancel must NOT trigger an upload',
      );
      expect(storage.capturedPatchUrl, isNull);
    });

    test('rejects payloads over kMaxAvatarBytes (5 MB) before uploading',
        () async {
      final Uint8List tooBig = Uint8List(kMaxAvatarBytes + 1);
      final _FakeSource src = _FakeSource(tooBig);
      final _FakeStorage storage = _FakeStorage();
      final AvatarUploadService svc = AvatarUploadService(
        source: src,
        storage: storage,
        userId: 'u-1',
      );
      await expectLater(
        svc.pickAndUpload(),
        throwsA(
          predicate<AvatarUploadException>(
            (Object? e) =>
                e is AvatarUploadException &&
                e.kind == AvatarUploadError.tooLarge,
          ),
        ),
      );
      expect(storage.capturedPath, isNull);
    });

    test('throws AuthRequired when userId is null', () async {
      final _FakeSource src = _FakeSource(Uint8List(1024));
      final _FakeStorage storage = _FakeStorage();
      final AvatarUploadService svc = AvatarUploadService(
        source: src,
        storage: storage,
        userId: null,
      );
      await expectLater(
        svc.pickAndUpload(),
        throwsA(
          predicate<AvatarUploadException>(
            (Object? e) =>
                e is AvatarUploadException &&
                e.kind == AvatarUploadError.authRequired,
          ),
        ),
      );
      expect(
        src.calls,
        0,
        reason: 'no session → bail before even prompting the picker',
      );
    });

    test('wraps picker exceptions as pickFailed', () async {
      final _FakeSource src =
          _FakeSource(null, throwable: StateError('photo permission denied'));
      final _FakeStorage storage = _FakeStorage();
      final AvatarUploadService svc = AvatarUploadService(
        source: src,
        storage: storage,
        userId: 'u-1',
      );
      await expectLater(
        svc.pickAndUpload(),
        throwsA(
          predicate<AvatarUploadException>(
            (Object? e) =>
                e is AvatarUploadException &&
                e.kind == AvatarUploadError.pickFailed,
          ),
        ),
      );
    });

    test('wraps upload exceptions as uploadFailed', () async {
      final _FakeSource src = _FakeSource(Uint8List(2048));
      final _FakeStorage storage = _FakeStorage()
        ..uploadThrowable = StateError('storage 5xx');
      final AvatarUploadService svc = AvatarUploadService(
        source: src,
        storage: storage,
        userId: 'u-1',
      );
      await expectLater(
        svc.pickAndUpload(),
        throwsA(
          predicate<AvatarUploadException>(
            (Object? e) =>
                e is AvatarUploadException &&
                e.kind == AvatarUploadError.uploadFailed,
          ),
        ),
      );
    });

    test('photo_url patch failure does NOT mask the upload (returns URL anyway)',
        () async {
      // Bytes are already in the bucket; surfacing the URL is still useful —
      // the edit form can retry the patch on the next save.
      final _FakeSource src = _FakeSource(Uint8List(2048));
      final _FakeStorage storage = _FakeStorage()
        ..patchThrowable = StateError('RLS denied');
      final AvatarUploadService svc = AvatarUploadService(
        source: src,
        storage: storage,
        userId: 'u-1',
      );
      final String? url = await svc.pickAndUpload();
      expect(url, isNotNull);
      expect(
        storage.capturedPath,
        'u-1/avatar.jpg',
        reason: 'upload still happened',
      );
    });
  });
}

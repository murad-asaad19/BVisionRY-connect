import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

/// 5 MB hard cap on the final compressed payload, matching the React Native
/// client (spec §13.4). Defence-in-depth — Supabase Storage has its own size
/// gate, but we surface a clean typed error before bytes leave the device.
const int kMaxAvatarBytes = 5 * 1024 * 1024;

/// Storage path inside the `avatars` bucket. `{userId}/avatar.jpg` is the
/// canonical path; RLS lets a user only write their own subtree.
String _avatarPath(String userId) => '$userId/avatar.jpg';

enum AvatarUploadError { tooLarge, authRequired, pickFailed, uploadFailed }

class AvatarUploadException implements Exception {
  AvatarUploadException(this.kind, [this.cause]);
  final AvatarUploadError kind;
  final Object? cause;
  @override
  String toString() => 'AvatarUploadException($kind, $cause)';
}

/// Test-seam abstraction over the device-side picker + cropper + compressor
/// pipeline. Production implementation in [DeviceAvatarSource] wires the
/// `image_picker` → `image_cropper` → `flutter_image_compress` chain; tests
/// inject in-memory byte buffers.
abstract class AvatarSource {
  /// Picks an image from gallery, crops it to a 1:1 square, compresses it
  /// (≤ ~800×800, JPEG q85), and returns the resulting byte buffer. Returns
  /// `null` if the user cancels at any step.
  Future<Uint8List?> pickAndCropSquareAvatar();
}

/// Real-device implementation of [AvatarSource]. Pipeline mirrors spec §13.3
/// verbatim — `pickImage` → `cropImage` (1:1, JPEG q90) → `compressWithFile`
/// (≤ 800×800, JPEG q85).
class DeviceAvatarSource implements AvatarSource {
  DeviceAvatarSource({
    ImagePicker? picker,
    ImageCropper? cropper,
  })  : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

  @override
  Future<Uint8List?> pickAndCropSquareAvatar() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (picked == null) return null;

    final CroppedFile? cropped = await _cropper.cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: <PlatformUiSettings>[
        AndroidUiSettings(
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(aspectRatioLockEnabled: true),
      ],
    );
    if (cropped == null) return null;

    final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
      cropped.path,
      minWidth: 800,
      minHeight: 800,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    return compressed;
  }
}

/// Test-seam abstraction over Supabase Storage + the profiles patch. The
/// concrete adapter binds to the live client; tests use an in-memory fake.
abstract class AvatarStorageGateway {
  Future<void> uploadAvatar({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  });

  String getPublicUrl(String path);

  Future<void> patchPhotoUrl({
    required String userId,
    required String url,
  });
}

class SupabaseAvatarStorageGateway implements AvatarStorageGateway {
  SupabaseAvatarStorageGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<void> uploadAvatar({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: upsert,
          ),
        );
  }

  @override
  String getPublicUrl(String path) =>
      _client.storage.from('avatars').getPublicUrl(path);

  @override
  Future<void> patchPhotoUrl({
    required String userId,
    required String url,
  }) async {
    await _client
        .from('profiles')
        .update(<String, dynamic>{'photo_url': url})
        .eq('id', userId);
  }
}

/// Coordinates the full avatar pipeline: pick → crop → compress → upload →
/// cache-bust → patch profiles.photo_url. Returns the new cache-busted URL.
///
/// `userId` is passed in (rather than read from `_client.auth`) so the
/// service stays decoupled from Supabase auth — the controller wires the
/// current session id at construction time.
class AvatarUploadService {
  AvatarUploadService({
    required AvatarSource source,
    required AvatarStorageGateway storage,
    required String? userId,
  })  : _source = source,
        _storage = storage,
        _userId = userId;

  final AvatarSource _source;
  final AvatarStorageGateway _storage;
  final String? _userId;

  /// Runs the full pipeline. Returns the new cache-busted public URL,
  /// `null` if the user cancels, or throws an [AvatarUploadException]
  /// when something goes wrong.
  Future<String?> pickAndUpload() async {
    final String? userId = _userId;
    if (userId == null) {
      throw AvatarUploadException(AvatarUploadError.authRequired);
    }

    Uint8List? bytes;
    try {
      bytes = await _source.pickAndCropSquareAvatar();
    } catch (e) {
      throw AvatarUploadException(AvatarUploadError.pickFailed, e);
    }
    if (bytes == null) return null;

    if (bytes.lengthInBytes > kMaxAvatarBytes) {
      throw AvatarUploadException(AvatarUploadError.tooLarge);
    }

    final String path = _avatarPath(userId);
    try {
      await _storage.uploadAvatar(
        path: path,
        bytes: bytes,
        contentType: 'image/jpeg',
        upsert: true,
      );
    } catch (e) {
      throw AvatarUploadException(AvatarUploadError.uploadFailed, e);
    }

    final String publicUrl = _storage.getPublicUrl(path);
    final String busted =
        '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _storage.patchPhotoUrl(userId: userId, url: busted);
    } catch (e) {
      // The bytes are already in the bucket — surfacing the URL is still
      // useful. The edit form can retry the patch on the next save.
      if (kDebugMode) debugPrint('avatar: photo_url patch failed: $e');
    }

    return busted;
  }
}

/// Wires [AvatarUploadService] to the live Supabase client. The current
/// session uid is read from `auth.currentUser` so the pipeline aborts cleanly
/// when the session is missing. Tests override directly with a fake.
final Provider<AvatarUploadService> avatarUploadServiceProvider =
    Provider<AvatarUploadService>((Ref<AvatarUploadService> ref) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return AvatarUploadService(
    source: DeviceAvatarSource(),
    storage: SupabaseAvatarStorageGateway(client),
    userId: client.auth.currentUser?.id,
  );
});

import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../chat/domain/message.dart';
import '../constants.dart';
import 'signed_url_cache.dart';

/// Test-seam abstraction over the Supabase Storage + RPC surface
/// MediaService touches. Concrete adapter binds to the live
/// [SupabaseClient]; unit tests inject a `mocktail`-driven [Mock] instead
/// of trying to wrangle Supabase's fluent `storage.from(...).upload(...)`
/// chain.
abstract class MediaGateway {
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int ttlSeconds,
  });

  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

class SupabaseMediaGateway implements MediaGateway {
  SupabaseMediaGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int ttlSeconds,
  }) {
    return _client.storage.from(bucket).createSignedUrl(path, ttlSeconds);
  }

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

/// Pick, resize, upload, and dispatch chat-media RPCs.
///
/// Responsibilities split across:
/// - [pickImage] + [resizeImage] — local-only, no network
/// - [validateImageBytes] / [validateVoiceBytes] — pre-upload guard rails
/// - [uploadChatMedia] — storage write to `chat-media/{conv}/{msg}/{file}`
/// - [getSignedUrl] — TTL-cached via [SignedUrlCache]
/// - [sendImageMessage] / [sendVoiceMessage] — SECURITY DEFINER RPCs that
///   insert the row + enqueue downstream work (transcript pipeline,
///   push fan-out).
class MediaService {
  MediaService(this._gateway, {String Function()? idGenerator, ImagePicker? picker})
    : _idGen = idGenerator ?? (() => const Uuid().v4()),
      _picker = picker ?? ImagePicker() {
    _signedUrls = SignedUrlCache(
      ttl: Duration(seconds: MediaConstants.signedUrlTtlSeconds),
      safetyWindow: const Duration(seconds: 5),
      fetcher: _fetchSignedUrl,
    );
  }

  static const String chatBucket = 'chat-media';

  final MediaGateway _gateway;
  final String Function() _idGen;
  final ImagePicker _picker;
  late final SignedUrlCache _signedUrls;

  /// Generates a client-side message id. Server accepts client-generated
  /// UUIDs so the upload path can include the id BEFORE the row exists.
  String generateMessageId() => _idGen();

  String chatMediaPath({
    required String conversationId,
    required String messageId,
    required String fileName,
  }) => '$conversationId/$messageId/$fileName';

  // --- Picking & resizing ---
  Future<XFile?> pickImage() async {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
  }

  Future<Uint8List> resizeImage(
    XFile file, {
    int maxPx = MediaConstants.imageMaxDimension,
  }) async {
    final bytes = await file.readAsBytes();
    final out = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxPx,
      minHeight: maxPx,
      quality: 88,
      format: CompressFormat.jpeg,
    );
    return out;
  }

  // --- Validation ---
  void validateImageBytes(Uint8List bytes, {required String mime}) {
    if (bytes.lengthInBytes > MediaConstants.maxImageBytes) {
      throw ValidationException('media.imageTooLargeBody');
    }
    if (!MediaConstants.allowedImageMimes.contains(mime)) {
      throw ValidationException('media.unsupportedTypeBody');
    }
  }

  void validateVoiceBytes(
    Uint8List bytes, {
    required String mime,
    required int durationMs,
  }) {
    if (bytes.lengthInBytes > MediaConstants.maxVoiceBytes) {
      throw ValidationException('media.voiceTooLargeBody');
    }
    if (durationMs > MediaConstants.maxVoiceMs) {
      throw ValidationException('media.voiceTooLongBody');
    }
    if (!MediaConstants.allowedVoiceMimes.contains(mime)) {
      throw ValidationException('media.unsupportedTypeBody');
    }
  }

  // --- Upload ---
  Future<String> uploadChatMedia({
    required String conversationId,
    required String messageId,
    required String fileName,
    required Uint8List bytes,
    required String mime,
  }) async {
    final path = chatMediaPath(
      conversationId: conversationId,
      messageId: messageId,
      fileName: fileName,
    );
    try {
      await _gateway.uploadBinary(
        bucket: chatBucket,
        path: path,
        bytes: bytes,
        contentType: mime,
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
    return path;
  }

  /// TTL-cached signed URL for a chat-media path. Returns a URL that is
  /// guaranteed valid for at least `safetyWindow` (5s) past TTL.
  Future<String> getSignedUrl(String path) => _signedUrls.get(path);

  /// Drops the cached URL for [path] — call after re-uploading to the
  /// same path (rare; messageId+filename composition normally prevents
  /// collisions).
  void invalidateSignedUrl(String path) => _signedUrls.invalidate(path);

  Future<String> _fetchSignedUrl(String path) {
    return _gateway.createSignedUrl(
      bucket: chatBucket,
      path: path,
      ttlSeconds: MediaConstants.signedUrlTtlSeconds,
    );
  }

  // --- RPCs ---
  Future<Message> sendImageMessage({
    required String conversationId,
    required String mediaPath,
    required String mediaMime,
    required int mediaSizeBytes,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'send_image_message',
        params: <String, dynamic>{
          'p_conversation_id': conversationId,
          'p_media_path': mediaPath,
          'p_media_mime': mediaMime,
          'p_media_size_bytes': mediaSizeBytes,
        },
      );
      return Message.fromRow(_singleRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  Future<Message> sendVoiceMessage({
    required String conversationId,
    required String mediaPath,
    required String mediaMime,
    required int mediaSizeBytes,
    required int durationMs,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'send_voice_message',
        params: <String, dynamic>{
          'p_conversation_id': conversationId,
          'p_media_path': mediaPath,
          'p_media_mime': mediaMime,
          'p_media_size_bytes': mediaSizeBytes,
          'p_duration_ms': durationMs,
        },
      );
      return Message.fromRow(_singleRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  Map<String, dynamic> _singleRow(Object? raw) {
    if (raw is List && raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }
}

/// Provider that exposes the configured [MediaService] singleton.
final Provider<MediaService> mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService(SupabaseMediaGateway(ref.watch(supabaseClientProvider)));
});

/// Family provider that returns a signed URL for a chat-media path. Used
/// by `ImageBubble` / `VoiceBubble` to render content from the private
/// bucket.
final AutoDisposeFutureProviderFamily<String, String>
signedChatMediaUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, path) {
      return ref.watch(mediaServiceProvider).getSignedUrl(path);
    });

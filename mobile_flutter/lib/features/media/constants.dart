/// Media upload limits and allowed MIME types, sourced from spec §13.4.
///
/// Centralised so feature code, validators, and UI copy can share the same
/// numbers. Bumping a limit requires updating the SECURITY DEFINER RPCs
/// that enforce the same bounds server-side; keep these aligned with
/// `supabase/migrations/*.sql`.
abstract final class MediaConstants {
  static const int maxAvatarBytes = 5 * 1024 * 1024;
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxVoiceBytes = 25 * 1024 * 1024;
  static const int maxVoiceMs = 120000;
  static const int imageMaxDimension = 1600;
  static const int signedUrlTtlSeconds = 60;

  static const List<String> allowedImageMimes = <String>[
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  static const List<String> allowedVoiceMimes = <String>[
    'audio/m4a',
    'audio/mp4',
    'audio/aac',
    'audio/webm',
  ];
}

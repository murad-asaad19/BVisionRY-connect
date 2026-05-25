/// Kind discriminator for a row in `public.messages` (spec §2.6).
///
/// Server enforces `kind IN ('text','image','voice','meeting')`. Direct
/// INSERTs by participants are restricted to `text` via RLS; the other
/// three kinds are produced exclusively by SECURITY DEFINER RPCs
/// (`send_image_message`, `send_voice_message`, `propose_meeting`).
enum MessageKind {
  text,
  image,
  voice,
  meeting;

  /// Wire value persisted to the DB column.
  String get dbValue => name;

  /// Parses a row value into a [MessageKind]. Unknown / null defaults to
  /// [text] so we never throw on forward-compat additions — the UI just
  /// shows the body verbatim.
  static MessageKind fromDb(String? raw) {
    switch (raw) {
      case 'image':
        return MessageKind.image;
      case 'voice':
        return MessageKind.voice;
      case 'meeting':
        return MessageKind.meeting;
      case 'text':
      default:
        return MessageKind.text;
    }
  }
}

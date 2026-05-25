import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:connect_mobile/features/chat/domain/transcript_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageKind', () {
    test('parses spec values', () {
      expect(MessageKind.fromDb('text'), MessageKind.text);
      expect(MessageKind.fromDb('image'), MessageKind.image);
      expect(MessageKind.fromDb('voice'), MessageKind.voice);
      expect(MessageKind.fromDb('meeting'), MessageKind.meeting);
      expect(MessageKind.fromDb('unknown'), MessageKind.text);
      expect(MessageKind.fromDb(null), MessageKind.text);
    });

    test('round-trips via dbValue', () {
      for (final k in MessageKind.values) {
        expect(MessageKind.fromDb(k.dbValue), k);
      }
    });
  });

  group('TranscriptStatus', () {
    test('parses spec values', () {
      expect(TranscriptStatus.fromDb('pending'), TranscriptStatus.pending);
      expect(
        TranscriptStatus.fromDb('processing'),
        TranscriptStatus.processing,
      );
      expect(TranscriptStatus.fromDb('ready'), TranscriptStatus.ready);
      expect(
        TranscriptStatus.fromDb('unsupported'),
        TranscriptStatus.unsupported,
      );
      expect(TranscriptStatus.fromDb('failed'), TranscriptStatus.failed);
      expect(TranscriptStatus.fromDb(null), isNull);
      expect(TranscriptStatus.fromDb('bogus'), TranscriptStatus.failed);
    });
  });
}

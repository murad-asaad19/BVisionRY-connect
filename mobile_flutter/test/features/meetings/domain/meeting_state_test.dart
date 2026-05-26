import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeetingState', () {
    test('fromJson maps each DB value', () {
      expect(MeetingState.fromJson('proposed'), MeetingState.proposed);
      expect(MeetingState.fromJson('confirmed'), MeetingState.confirmed);
      expect(MeetingState.fromJson('declined'), MeetingState.declined);
      expect(MeetingState.fromJson('cancelled'), MeetingState.cancelled);
    });

    test('fromJson throws on unknown value', () {
      expect(() => MeetingState.fromJson('expired'), throwsArgumentError);
    });

    test('toJson is the DB string', () {
      expect(MeetingState.proposed.toJson(), 'proposed');
      expect(MeetingState.confirmed.toJson(), 'confirmed');
      expect(MeetingState.declined.toJson(), 'declined');
      expect(MeetingState.cancelled.toJson(), 'cancelled');
    });

    test('isOpen returns true only for proposed', () {
      expect(MeetingState.proposed.isOpen, isTrue);
      expect(MeetingState.confirmed.isOpen, isFalse);
      expect(MeetingState.declined.isOpen, isFalse);
      expect(MeetingState.cancelled.isOpen, isFalse);
    });
  });
}

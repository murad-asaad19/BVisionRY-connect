import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGateway extends Mock implements OfficeHoursGateway {}

void main() {
  late _MockGateway gateway;
  late OfficeHoursService svc;

  setUp(() {
    gateway = _MockGateway();
    svc = OfficeHoursService(gateway);
  });

  group('setOfficeHours', () {
    test('passes args as snake_case and parses the row response', () async {
      when(
        () => gateway.rpc('set_office_hours', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'user_id': 'me',
          'enabled': true,
          'windows': <Map<String, dynamic>>[
            <String, dynamic>{
              'weekday': 1,
              'start_minute': 540,
              'end_minute': 660,
              'timezone': 'UTC',
            },
          ],
          'slot_duration_minutes': 30,
          'max_bookings_per_week': 5,
          'buffer_minutes': 5,
          'meeting_link_template': null,
          'notes_template': null,
          'updated_at': '2026-05-25T00:00:00Z',
        },
      );

      final s = await svc.setOfficeHours(
        enabled: true,
        windows: const <OfficeHoursWindow>[
          OfficeHoursWindow(
            weekday: 1,
            startMinute: 540,
            endMinute: 660,
            timezone: 'UTC',
          ),
        ],
        slotDurationMinutes: 30,
        maxBookingsPerWeek: 5,
        bufferMinutes: 5,
      );

      expect(s.enabled, isTrue);
      expect(s.slotDurationMinutes, 30);

      final captured = verify(
        () => gateway.rpc(
          'set_office_hours',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_enabled'], isTrue);
      expect(
        (captured['p_windows'] as List).first,
        containsPair('start_minute', 540),
      );
      expect(captured['p_slot_duration_minutes'], 30);
    });

    test('postgrest error funnels through mapPostgrestError', () async {
      when(
        () => gateway.rpc('set_office_hours', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'bad',
          code: 'P0001',
          hint: 'blocked',
        ),
      );
      await expectLater(
        svc.setOfficeHours(
          enabled: true,
          windows: const <OfficeHoursWindow>[],
          slotDurationMinutes: 30,
          maxBookingsPerWeek: 5,
          bufferMinutes: 5,
        ),
        throwsA(isA<BlockedException>()),
      );
    });
  });

  group('myOfficeHoursSettings', () {
    test('returns parsed defaults from the RPC', () async {
      when(() => gateway.rpc('my_office_hours_settings')).thenAnswer(
        (_) async => <String, dynamic>{
          'user_id': 'me',
          'enabled': false,
          'windows': <Map<String, dynamic>>[],
          'slot_duration_minutes': 15,
          'max_bookings_per_week': 5,
          'buffer_minutes': 5,
          'meeting_link_template': null,
          'notes_template': null,
          'updated_at': null,
        },
      );
      final s = await svc.myOfficeHoursSettings();
      expect(s.enabled, isFalse);
      expect(s.windows, isEmpty);
    });
  });

  group('listUpcomingSlots', () {
    test('parses an array of rows', () async {
      when(
        () => gateway.rpc('list_upcoming_slots', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 's1',
            'host_id': 'h1',
            'starts_at': '2026-06-01T15:00:00Z',
            'ends_at': '2026-06-01T15:30:00Z',
            'status': 'open',
            'host_settings_notes_template': null,
          },
        ],
      );
      final slots = await svc.listUpcomingSlots('h1');
      expect(slots, hasLength(1));
      expect(slots.first.id, 's1');
      expect(slots.first.status, SlotStatus.open);
    });
  });

  group('bookSlot', () {
    test('returns the meeting_proposal_id string', () async {
      when(
        () => gateway.rpc('book_slot', params: any(named: 'params')),
      ).thenAnswer((_) async => 'mp-123');
      final id =
          await svc.bookSlot(slotId: 's1', topic: 'Career advice please');
      expect(id, 'mp-123');
    });

    test('maps slot_unavailable to SlotUnavailableException', () async {
      when(
        () => gateway.rpc('book_slot', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'unavailable',
          code: 'P0001',
          hint: 'slot_unavailable',
        ),
      );
      expect(
        () => svc.bookSlot(slotId: 's1', topic: 'A topic of mine'),
        throwsA(isA<SlotUnavailableException>()),
      );
    });

    test('maps slot_too_soon to SlotTooSoonException', () async {
      when(
        () => gateway.rpc('book_slot', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'soon',
          code: 'P0001',
          hint: 'slot_too_soon',
        ),
      );
      expect(
        () => svc.bookSlot(slotId: 's1', topic: 'A topic of mine'),
        throwsA(isA<SlotTooSoonException>()),
      );
    });

    test('maps weekly_cap to WeeklyCapException', () async {
      when(
        () => gateway.rpc('book_slot', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'cap',
          code: 'P0001',
          hint: 'weekly_cap',
        ),
      );
      expect(
        () => svc.bookSlot(slotId: 's1', topic: 'A topic of mine'),
        throwsA(isA<WeeklyCapException>()),
      );
    });

    test('maps blocked to BlockedException', () async {
      when(
        () => gateway.rpc('book_slot', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'blocked',
          code: 'P0001',
          hint: 'blocked',
        ),
      );
      expect(
        () => svc.bookSlot(slotId: 's1', topic: 'A topic of mine'),
        throwsA(isA<BlockedException>()),
      );
    });

    test('maps oh_disabled to OhDisabledException', () async {
      when(
        () => gateway.rpc('book_slot', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'off',
          code: 'P0001',
          hint: 'oh_disabled',
        ),
      );
      expect(
        () => svc.bookSlot(slotId: 's1', topic: 'A topic of mine'),
        throwsA(isA<OhDisabledException>()),
      );
    });

    test('maps host_self to HostSelfException', () async {
      when(
        () => gateway.rpc('book_slot', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'self',
          code: 'P0001',
          hint: 'host_self',
        ),
      );
      expect(
        () => svc.bookSlot(slotId: 's1', topic: 'A topic of mine'),
        throwsA(isA<HostSelfException>()),
      );
    });
  });

  group('cancelBooking', () {
    test('completes without throwing on success', () async {
      when(
        () => gateway.rpc('cancel_booking', params: any(named: 'params')),
      ).thenAnswer((_) async => null);
      await svc.cancelBooking('s1');
      verify(
        () => gateway.rpc(
          'cancel_booking',
          params: <String, dynamic>{'p_slot_id': 's1'},
        ),
      ).called(1);
    });

    test('maps not_authorised to ForbiddenException', () async {
      when(
        () => gateway.rpc('cancel_booking', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'na',
          code: 'P0001',
          hint: 'not_authorised',
        ),
      );
      expect(
        () => svc.cancelBooking('s1'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('myBookings', () {
    test('parses an array of MyBooking', () async {
      when(() => gateway.rpc('my_bookings')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'slot_id': 's1',
            'host_id': 'h1',
            'host_handle': 'rida',
            'host_name': 'Rida G',
            'host_photo_url': null,
            'starts_at': '2026-06-01T15:00:00Z',
            'ends_at': '2026-06-01T15:30:00Z',
            'topic': 'A topic',
            'meeting_proposal_id': 'mp1',
          },
        ],
      );
      final rows = await svc.myBookings();
      expect(rows, hasLength(1));
      expect(rows.first.hostHandle, 'rida');
    });
  });

  group('conversationIdForProposal', () {
    test('reads conversation_id from meeting_proposals', () async {
      when(() => gateway.meetingProposalById('mp1')).thenAnswer(
        (_) async => <String, dynamic>{'conversation_id': 'c1'},
      );
      final id = await svc.conversationIdForProposal('mp1');
      expect(id, 'c1');
    });
  });
}

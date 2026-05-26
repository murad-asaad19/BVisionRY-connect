import 'package:connect_mobile/features/meetings/data/meeting_playbook_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_playbook.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGateway extends Mock implements MeetingPlaybookGateway {}

void main() {
  late _MockGateway gateway;
  late MeetingPlaybookService svc;

  setUp(() {
    gateway = _MockGateway();
    svc = MeetingPlaybookService(gateway);
  });

  test('fetchPlaybook returns null on empty RPC result', () async {
    when(
      () => gateway.rpc('get_meeting_playbook', params: any(named: 'params')),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
    final p = await svc.fetchPlaybook('mid');
    expect(p, isNull);
  });

  test('fetchPlaybook parses first row of a list response', () async {
    when(
      () => gateway.rpc('get_meeting_playbook', params: any(named: 'params')),
    ).thenAnswer((_) async => [_row()]);
    final p = await svc.fetchPlaybook('mid');
    expect(p, isA<MeetingPlaybook>());
    expect(p!.meetingId, 'mid');
  });

  test('fetchPlaybook parses single-object response', () async {
    when(
      () => gateway.rpc('get_meeting_playbook', params: any(named: 'params')),
    ).thenAnswer((_) async => _row());
    final p = await svc.fetchPlaybook('mid');
    expect(p!.meetingId, 'mid');
  });

  test('regeneratePlaybook invokes meeting-playbook with force flag', () async {
    when(
      () => gateway.invokeFunction(
        'meeting-playbook',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => FunctionResponse(data: _row(), status: 200),
    );
    final p = await svc.regeneratePlaybook('mid', force: true);
    expect(p.meetingId, 'mid');
    verify(
      () => gateway.invokeFunction(
        'meeting-playbook',
        body: {'meeting_id': 'mid', 'force': true},
      ),
    ).called(1);
  });
}

Map<String, dynamic> _row() => {
      'meeting_id': 'mid',
      'viewer_id': 'vid',
      'target_id': 'tid',
      'summary': 'About them',
      'shared_interests': ['a', 'b', 'c'],
      'conversation_starters': ['1', '2', '3'],
      'do_notes': ['x', 'y'],
      'dont_notes': ['z'],
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };

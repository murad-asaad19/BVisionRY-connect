import 'dart:convert';
import 'dart:io';

import 'package:connect_mobile/features/meetings/data/ics_service.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.dir);
  final Directory dir;
  @override
  Future<String?> getTemporaryPath() async => dir.path;
}

void main() {
  group('formatICSDate', () {
    test('formats UTC in YYYYMMDDTHHmmssZ', () {
      final d = DateTime.utc(2026, 6, 1, 15, 30, 0);
      expect(formatICSDate(d), '20260601T153000Z');
    });

    test('always uses UTC even if input is local', () {
      final local = DateTime(2026, 6, 1, 15, 30, 0);
      expect(formatICSDate(local), formatICSDate(local.toUtc()));
    });

    test('zero-pads year/month/day/hour/minute/second', () {
      final d = DateTime.utc(2026, 1, 2, 3, 4, 5);
      expect(formatICSDate(d), '20260102T030405Z');
    });
  });

  group('escapeICS', () {
    test('escapes backslash first, then ; , and newline', () {
      expect(escapeICS('hello'), 'hello');
      expect(escapeICS('a;b'), r'a\;b');
      expect(escapeICS('a,b'), r'a\,b');
      expect(escapeICS('a\\b'), r'a\\b');
      expect(escapeICS('line1\nline2'), r'line1\nline2');
      // Backslash escape applied BEFORE others so an input \; becomes \\;
      expect(escapeICS('a\\;b'), r'a\\\;b');
    });
  });

  group('foldLine', () {
    test('returns single line <=75 octets unchanged', () {
      const ascii = 'SUMMARY:Hello world';
      expect(foldLine(ascii), ascii);
    });

    test('folds ASCII line >75 octets at 75-byte boundary with " " continuation',
        () {
      final long = 'X' * 100;
      final folded = foldLine(long);
      final lines = folded.split('\r\n');
      expect(lines.length, 2);
      expect(lines[0].length, 75);
      expect(lines[1].startsWith(' '), isTrue);
      // continuation reserves 1 byte for leading space, leaving 74 — and the
      // first line consumed 75, so the remaining 25 chars all fit
      expect(lines[1].substring(1), 'X' * 25);
    });

    test('UTF-8 multi-byte: does not split inside a 3-byte codepoint', () {
      // U+2603 (snowman) is 3 bytes in UTF-8 (e2 98 83).
      final prefix = 'A' * 73; // 73 bytes
      final input = '$prefix☃☃'; // 73 + 3 + 3 = 79 bytes
      final folded = foldLine(input);
      final lines = folded.split('\r\n');
      final firstBytes = utf8.encode(lines[0]);
      expect(firstBytes.length, lessThanOrEqualTo(75));
      // Decoding the first chunk alone must succeed (no partial codepoint).
      expect(() => utf8.decode(firstBytes), returnsNormally);
      expect(lines[1].startsWith(' '), isTrue);
      // Concatenating dropped-space continuation re-yields the original.
      final joined =
          lines[0] + lines.skip(1).map((l) => l.substring(1)).join();
      expect(joined, input);
    });

    test('folds a very long UTF-8 line into multiple continuation lines',
        () {
      final input = '☃' * 60; // 60 snowmen = 180 bytes
      final folded = foldLine(input);
      final lines = folded.split('\r\n');
      expect(lines.length, greaterThanOrEqualTo(3));
      for (final l in lines) {
        expect(utf8.encode(l).length, lessThanOrEqualTo(75));
      }
      final joined =
          lines[0] + lines.skip(1).map((l) => l.substring(1)).join();
      expect(joined, input);
    });
  });

  group('generateIcsFile', () {
    late Directory tmp;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tmp = await Directory.systemTemp.createTemp('ics_test');
      PathProviderPlatform.instance = _FakePathProvider(tmp);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('produces a well-formed VCALENDAR with required properties',
        () async {
      final svc = IcsService();
      final file = await svc.generateIcsFile(
        meetingId: '11111111-2222-3333-4444-555555555555',
        title: 'Coffee with Tara',
        description: 'Catch-up; talk about design systems',
        startUtc: DateTime.utc(2026, 6, 1, 15, 0),
        endUtc: DateTime.utc(2026, 6, 1, 15, 30),
        attendeesEmails: const ['a@b.com', 'c@d.com'],
        location: 'https://meet.google.com/abc-defg-hij',
      );
      final body = await file.readAsString();
      expect(body, startsWith('BEGIN:VCALENDAR\r\n'));
      expect(body, endsWith('END:VCALENDAR\r\n'));
      expect(body, contains('VERSION:2.0'));
      expect(body, contains('PRODID:-//BVisionry//Connect//EN'));
      expect(
        body,
        contains('UID:meeting-11111111-2222-3333-4444-555555555555@bvisionry.com'),
      );
      expect(body, contains('DTSTART:20260601T150000Z'));
      expect(body, contains('DTEND:20260601T153000Z'));
      expect(body, contains('SUMMARY:Coffee with Tara'));
      expect(body, contains(r'DESCRIPTION:Catch-up\; talk about design systems'));
      expect(body, contains('LOCATION:https://meet.google.com/abc-defg-hij'));
      expect(body, contains('ATTENDEE;CN=a@b.com:mailto:a@b.com'));
      expect(body, contains('ATTENDEE;CN=c@d.com:mailto:c@d.com'));
    });

    test('escapes commas, semicolons and newlines in title/description',
        () async {
      final svc = IcsService();
      final file = await svc.generateIcsFile(
        meetingId: 'aaaaaaaaaa',
        title: 'A; B, C',
        description: 'line1\nline2',
        startUtc: DateTime.utc(2026, 6, 1, 15, 0),
        endUtc: DateTime.utc(2026, 6, 1, 15, 30),
        attendeesEmails: const [],
        location: null,
      );
      final body = await file.readAsString();
      expect(body, contains(r'SUMMARY:A\; B\, C'));
      expect(body, contains(r'DESCRIPTION:line1\nline2'));
    });

    test('every physical line <=75 octets even with long content', () async {
      final svc = IcsService();
      final file = await svc.generateIcsFile(
        meetingId: 'aaaaaaaaaa',
        title: 'X' * 200,
        description: '☃' * 80,
        startUtc: DateTime.utc(2026, 6, 1, 15, 0),
        endUtc: DateTime.utc(2026, 6, 1, 15, 30),
        attendeesEmails: const [],
        location: null,
      );
      final body = await file.readAsString();
      // Drop trailing empty line from final CRLF.
      final physicalLines =
          body.split('\r\n').where((l) => l.isNotEmpty).toList();
      for (final line in physicalLines) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
      }
    });

    test('writes to a meeting-{shortId}.ics filename', () async {
      final svc = IcsService();
      final file = await svc.generateIcsFile(
        meetingId: 'aabbccddeeff112233',
        title: 't',
        description: 'd',
        startUtc: DateTime.utc(2026, 6, 1, 15, 0),
        endUtc: DateTime.utc(2026, 6, 1, 15, 30),
        attendeesEmails: const [],
        location: null,
      );
      expect(file.path, endsWith('meeting-aabbccdd.ics'));
    });
  });
}

import 'package:connect_mobile/features/opportunities/domain/interested_user.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_counts.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseRow({
  String kind = 'hiring',
  String? city = 'Lisbon',
  String? country = 'PT',
  bool remoteOk = true,
  String status = 'open',
  Object? tags = const <String>['pm', 'fintech'],
  String? closedAt,
}) {
  return <String, dynamic>{
    'id': 'a' * 36,
    'author_id': 'b' * 36,
    'kind': kind,
    'title': 'Hiring a senior PM',
    'body': 'Tell us if you ship.',
    'tags': tags,
    'location_city': city,
    'location_country': country,
    'remote_ok': remoteOk,
    'status': status,
    'expires_at': '2026-07-25T00:00:00Z',
    'created_at': '2026-05-25T00:00:00Z',
    'updated_at': '2026-05-25T00:00:00Z',
    'closed_at': closedAt,
  };
}

Map<String, dynamic> _withAuthor(Map<String, dynamic> row) => <String, dynamic>{
      ...row,
      'author_handle': 'jane',
      'author_name': 'Jane Doe',
      'author_photo_url': null,
      'author_primary_role': 'founder',
      'author_verified_github_username': null,
    };

void main() {
  group('Opportunity.fromJson', () {
    test('parses a full row', () {
      final Opportunity o = Opportunity.fromJson(_baseRow());
      expect(o.id.length, 36);
      expect(o.kind, OpportunityKind.hiring);
      expect(o.status, OpportunityStatus.open);
      expect(o.tags, <String>['pm', 'fintech']);
      expect(o.remoteOk, isTrue);
      expect(o.closedAt, isNull);
      expect(o.expiresAt.year, 2026);
      expect(o.expiresAt.isUtc, isTrue);
    });

    test('handles null tags as empty list', () {
      final Opportunity o = Opportunity.fromJson(
        _baseRow(
          kind: 'collaboration',
          tags: null,
          city: null,
          country: null,
          remoteOk: false,
        ),
      );
      expect(o.tags, isEmpty);
      expect(o.locationCity, isNull);
      expect(o.locationCountry, isNull);
      expect(o.remoteOk, isFalse);
      expect(o.kind, OpportunityKind.collaboration);
    });

    test('parses closed status with closed_at timestamp', () {
      final Opportunity o = Opportunity.fromJson(
        _baseRow(status: 'closed', closedAt: '2026-05-26T00:00:00Z'),
      );
      expect(o.status, OpportunityStatus.closed);
      expect(o.closedAt, isNotNull);
      expect(o.closedAt!.isUtc, isTrue);
    });
  });

  group('OpportunityWithAuthor.fromJson', () {
    test('parses join shape', () {
      final OpportunityWithAuthor j = OpportunityWithAuthor.fromJson(
        _withAuthor(_baseRow()),
      );
      expect(j.opportunity.kind.dbValue, 'hiring');
      expect(j.authorHandle, 'jane');
      expect(j.authorName, 'Jane Doe');
      expect(j.authorPrimaryRole, 'founder');
      expect(j.authorVerifiedGithubUsername, isNull);
      expect(j.interestedCount, isNull);
    });

    test('parses interested_count when present', () {
      final OpportunityWithAuthor j = OpportunityWithAuthor.fromJson(
        <String, dynamic>{
          ..._withAuthor(_baseRow()),
          'interested_count': 4,
        },
      );
      expect(j.interestedCount, 4);
    });
  });

  group('OpportunityWithCounts.fromJson', () {
    test('parses detail shape', () {
      final OpportunityWithCounts d = OpportunityWithCounts.fromJson(
        <String, dynamic>{
          ..._withAuthor(_baseRow(kind: 'cofounder')),
          'interested_count': 4,
          'viewer_has_expressed_interest': true,
        },
      );
      expect(d.interestedCount, 4);
      expect(d.viewerHasExpressedInterest, isTrue);
      expect(d.withAuthor.authorHandle, 'jane');
      expect(d.withAuthor.opportunity.kind.dbValue, 'cofounder');
    });
  });

  group('InterestedUser.fromJson', () {
    test('parses row from list_interested', () {
      final InterestedUser u = InterestedUser.fromJson(<String, dynamic>{
        'user_id': 'u' * 36,
        'handle': 'sam',
        'name': 'Sam Patel',
        'photo_url': 'https://example.com/sam.jpg',
        'primary_role': 'engineer',
        'note': 'Excited about your stack.',
        'created_at': '2026-05-25T10:00:00Z',
      });
      expect(u.userId.length, 36);
      expect(u.handle, 'sam');
      expect(u.note, contains('stack'));
      expect(u.createdAt.isUtc, isTrue);
    });
  });
}

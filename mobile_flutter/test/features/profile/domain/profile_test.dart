// Profile freezed model — covers full profiles-table schema (spec §2.2).
//
// The model is the canonical source of truth in Phase 4 and onwards; the
// Phase 2 hand-written stub at lib/features/auth/domain/profile.dart now
// re-exports this freezed class. Phase 2's `Profile.fromMap` open-Map contract
// is preserved so the existing ProfileRepository continues to compile.
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile', () {
    test('parses a complete row from JSON', () {
      final json = <String, dynamic>{
        'id': '11111111-1111-1111-1111-111111111111',
        'handle': 'sara-k',
        'name': 'Sara K',
        'headline': 'Building B2B fintech',
        'bio': 'Pre-seed founder building B2B fintech for SMEs.',
        'roles': <String>['founder', 'investor'],
        'primary_role': 'founder',
        'city': 'London',
        'country': 'UK',
        'goal_type': 'hire',
        'goal_text': 'Hire a senior backend engineer as CTO',
        'goal_updated_at': '2026-04-01T09:00:00Z',
        'photo_url': 'https://example.com/avatar.jpg?v=1700000000000',
        'onboarded': true,
        'verified_github_username': 'sarak',
        'verified_github_id': 4242,
        'verified_at': '2026-03-01T09:00:00Z',
        'suspended_at': null,
        'private_mode': false,
        'read_receipts_enabled': false,
        'public_investor_page': false,
        'created_at': '2026-01-01T09:00:00Z',
        'updated_at': '2026-04-01T09:00:00Z',
      };
      final Profile p = Profile.fromJson(json);
      expect(p.handle, 'sara-k');
      expect(p.roles, <String>['founder', 'investor']);
      expect(p.primaryRole, 'founder');
      expect(p.goalUpdatedAt, isNotNull);
      expect(p.verifiedGithubUsername, 'sarak');
      expect(p.verifiedGithubId, 4242);
      expect(p.privateMode, isFalse);
      expect(p.onboarded, isTrue);
      expect(p.publicInvestorPage, isFalse);
      expect(p.readReceiptsEnabled, isFalse);
    });

    test('handles nullable columns (pre-onboarding row)', () {
      final Profile p = Profile.fromJson(<String, dynamic>{
        'id': '11111111-1111-1111-1111-111111111111',
        'handle': null,
        'name': null,
        'headline': null,
        'bio': null,
        'roles': <String>[],
        'primary_role': null,
        'city': null,
        'country': null,
        'goal_type': null,
        'goal_text': null,
        'goal_updated_at': null,
        'photo_url': null,
        'onboarded': false,
        'verified_github_username': null,
        'verified_github_id': null,
        'verified_at': null,
        'suspended_at': null,
        'private_mode': false,
        'read_receipts_enabled': false,
        'public_investor_page': false,
        'created_at': null,
        'updated_at': null,
      });
      expect(p.handle, isNull);
      expect(p.onboarded, isFalse);
      expect(p.roles, isEmpty);
      expect(p.createdAt, isNull);
      expect(p.updatedAt, isNull);
    });

    test('fromMap is backwards-compatible with Phase 2 minimal rows', () {
      // Phase 2 only persists/reads a subset of columns. Profile.fromMap must
      // accept open-shaped Maps so ProfileRepository keeps working without a
      // sweeping refactor.
      final Profile p = Profile.fromMap(<String, dynamic>{
        'id': 'u-9',
        'onboarded': true,
        'suspended_at': null,
        'handle': 'h',
        'name': 'n',
        'private_mode': false,
      });
      expect(p.id, 'u-9');
      expect(p.onboarded, isTrue);
      expect(p.handle, 'h');
      expect(p.privateMode, isFalse);
      expect(p.suspendedAt, isNull);
    });

    test('isVerified true iff verified_github_username present', () {
      expect(Profile.empty('u').isVerified, isFalse);
      expect(
        Profile.empty('u').copyWith(verifiedGithubUsername: 'omar').isVerified,
        isTrue,
      );
    });

    test('isSuspended true iff suspended_at present', () {
      expect(Profile.empty('u').isSuspended, isFalse);
      expect(
        Profile.empty('u')
            .copyWith(suspendedAt: DateTime.utc(2026))
            .isSuspended,
        isTrue,
      );
    });

    test('isGoalStale returns true when goal_updated_at > 28 days ago', () {
      final Profile stale = Profile.empty('u').copyWith(
        goalUpdatedAt:
            DateTime.now().toUtc().subtract(const Duration(days: 30)),
      );
      final Profile fresh = Profile.empty('u').copyWith(
        goalUpdatedAt:
            DateTime.now().toUtc().subtract(const Duration(days: 10)),
      );
      final Profile never = Profile.empty('u');
      expect(stale.isGoalStale, isTrue);
      expect(fresh.isGoalStale, isFalse);
      expect(never.isGoalStale, isFalse);
    });
  });
}

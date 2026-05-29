// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      handle: json['handle'] as String?,
      name: json['name'] as String?,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      primaryRole: json['primary_role'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      goalType: json['goal_type'] as String?,
      goalText: json['goal_text'] as String?,
      goalUpdatedAt: json['goal_updated_at'] == null
          ? null
          : DateTime.parse(json['goal_updated_at'] as String),
      photoUrl: json['photo_url'] as String?,
      onboarded: json['onboarded'] as bool? ?? false,
      verifiedGithubUsername: json['verified_github_username'] as String?,
      verifiedGithubId: (json['verified_github_id'] as num?)?.toInt(),
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      suspendedAt: json['suspended_at'] == null
          ? null
          : DateTime.parse(json['suspended_at'] as String),
      privateMode: json['private_mode'] as bool? ?? false,
      readReceiptsEnabled: json['read_receipts_enabled'] as bool? ?? false,
      publicInvestorPage: json['public_investor_page'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      lastActiveAt: json['last_active_at'] == null
          ? null
          : DateTime.parse(json['last_active_at'] as String),
      tosAcceptedAt: json['tos_accepted_at'] == null
          ? null
          : DateTime.parse(json['tos_accepted_at'] as String),
      privacyAcceptedAt: json['privacy_accepted_at'] == null
          ? null
          : DateTime.parse(json['privacy_accepted_at'] as String),
      builderDiscipline: json['builder_discipline'] as String?,
      builderSeniority: json['builder_seniority'] as String?,
      builderSkills: (json['builder_skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      builderOpenTo: (json['builder_open_to'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      builderRateBand: json['builder_rate_band'] as String?,
      founderStage: json['founder_stage'] as String?,
      founderSector: json['founder_sector'] as String?,
      founderFunding: json['founder_funding'] as String?,
      founderHiring: json['founder_hiring'] as bool?,
      investorType: json['investor_type'] as String?,
      investorCheckSize: json['investor_check_size'] as String?,
      investorSectors: (json['investor_sectors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      investorStage: json['investor_stage'] as String?,
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'handle': instance.handle,
      'name': instance.name,
      'headline': instance.headline,
      'bio': instance.bio,
      'roles': instance.roles,
      'primary_role': instance.primaryRole,
      'city': instance.city,
      'country': instance.country,
      'goal_type': instance.goalType,
      'goal_text': instance.goalText,
      'goal_updated_at': instance.goalUpdatedAt?.toIso8601String(),
      'photo_url': instance.photoUrl,
      'onboarded': instance.onboarded,
      'verified_github_username': instance.verifiedGithubUsername,
      'verified_github_id': instance.verifiedGithubId,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'suspended_at': instance.suspendedAt?.toIso8601String(),
      'private_mode': instance.privateMode,
      'read_receipts_enabled': instance.readReceiptsEnabled,
      'public_investor_page': instance.publicInvestorPage,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
      'tos_accepted_at': instance.tosAcceptedAt?.toIso8601String(),
      'privacy_accepted_at': instance.privacyAcceptedAt?.toIso8601String(),
      'builder_discipline': instance.builderDiscipline,
      'builder_seniority': instance.builderSeniority,
      'builder_skills': instance.builderSkills,
      'builder_open_to': instance.builderOpenTo,
      'builder_rate_band': instance.builderRateBand,
      'founder_stage': instance.founderStage,
      'founder_sector': instance.founderSector,
      'founder_funding': instance.founderFunding,
      'founder_hiring': instance.founderHiring,
      'investor_type': instance.investorType,
      'investor_check_size': instance.investorCheckSize,
      'investor_sectors': instance.investorSectors,
      'investor_stage': instance.investorStage,
    };

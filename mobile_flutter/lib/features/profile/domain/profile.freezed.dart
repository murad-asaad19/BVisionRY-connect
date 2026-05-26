// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  String? get handle => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get headline => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_role')
  String? get primaryRole => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_type')
  String? get goalType => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_text')
  String? get goalText => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_updated_at')
  DateTime? get goalUpdatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  bool get onboarded => throw _privateConstructorUsedError;
  @JsonKey(name: 'verified_github_username')
  String? get verifiedGithubUsername => throw _privateConstructorUsedError;
  @JsonKey(name: 'verified_github_id')
  int? get verifiedGithubId => throw _privateConstructorUsedError;
  @JsonKey(name: 'verified_at')
  DateTime? get verifiedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'suspended_at')
  DateTime? get suspendedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'private_mode')
  bool get privateMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'read_receipts_enabled')
  bool get readReceiptsEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'public_investor_page')
  bool get publicInvestorPage => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_active_at')
  DateTime? get lastActiveAt =>
      throw _privateConstructorUsedError; // Role-specific structured details (spec §3a). All optional; the profile
// screen renders only the rows that resolve to a non-null value.
// Builder details
  @JsonKey(name: 'builder_discipline')
  String? get builderDiscipline => throw _privateConstructorUsedError;
  @JsonKey(name: 'builder_seniority')
  String? get builderSeniority => throw _privateConstructorUsedError;
  @JsonKey(name: 'builder_skills')
  List<String> get builderSkills => throw _privateConstructorUsedError;
  @JsonKey(name: 'builder_open_to')
  List<String> get builderOpenTo => throw _privateConstructorUsedError;
  @JsonKey(name: 'builder_rate_band')
  String? get builderRateBand =>
      throw _privateConstructorUsedError; // Founder details
  @JsonKey(name: 'founder_stage')
  String? get founderStage => throw _privateConstructorUsedError;
  @JsonKey(name: 'founder_sector')
  String? get founderSector => throw _privateConstructorUsedError;
  @JsonKey(name: 'founder_funding')
  String? get founderFunding => throw _privateConstructorUsedError;
  @JsonKey(name: 'founder_hiring')
  bool? get founderHiring =>
      throw _privateConstructorUsedError; // Investor details
  @JsonKey(name: 'investor_type')
  String? get investorType => throw _privateConstructorUsedError;
  @JsonKey(name: 'investor_check_size')
  String? get investorCheckSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'investor_sectors')
  List<String> get investorSectors => throw _privateConstructorUsedError;
  @JsonKey(name: 'investor_stage')
  String? get investorStage => throw _privateConstructorUsedError;

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call(
      {String id,
      String? handle,
      String? name,
      String? headline,
      String? bio,
      List<String> roles,
      @JsonKey(name: 'primary_role') String? primaryRole,
      String? city,
      String? country,
      @JsonKey(name: 'goal_type') String? goalType,
      @JsonKey(name: 'goal_text') String? goalText,
      @JsonKey(name: 'goal_updated_at') DateTime? goalUpdatedAt,
      @JsonKey(name: 'photo_url') String? photoUrl,
      bool onboarded,
      @JsonKey(name: 'verified_github_username') String? verifiedGithubUsername,
      @JsonKey(name: 'verified_github_id') int? verifiedGithubId,
      @JsonKey(name: 'verified_at') DateTime? verifiedAt,
      @JsonKey(name: 'suspended_at') DateTime? suspendedAt,
      @JsonKey(name: 'private_mode') bool privateMode,
      @JsonKey(name: 'read_receipts_enabled') bool readReceiptsEnabled,
      @JsonKey(name: 'public_investor_page') bool publicInvestorPage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
      @JsonKey(name: 'builder_discipline') String? builderDiscipline,
      @JsonKey(name: 'builder_seniority') String? builderSeniority,
      @JsonKey(name: 'builder_skills') List<String> builderSkills,
      @JsonKey(name: 'builder_open_to') List<String> builderOpenTo,
      @JsonKey(name: 'builder_rate_band') String? builderRateBand,
      @JsonKey(name: 'founder_stage') String? founderStage,
      @JsonKey(name: 'founder_sector') String? founderSector,
      @JsonKey(name: 'founder_funding') String? founderFunding,
      @JsonKey(name: 'founder_hiring') bool? founderHiring,
      @JsonKey(name: 'investor_type') String? investorType,
      @JsonKey(name: 'investor_check_size') String? investorCheckSize,
      @JsonKey(name: 'investor_sectors') List<String> investorSectors,
      @JsonKey(name: 'investor_stage') String? investorStage});
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = freezed,
    Object? name = freezed,
    Object? headline = freezed,
    Object? bio = freezed,
    Object? roles = null,
    Object? primaryRole = freezed,
    Object? city = freezed,
    Object? country = freezed,
    Object? goalType = freezed,
    Object? goalText = freezed,
    Object? goalUpdatedAt = freezed,
    Object? photoUrl = freezed,
    Object? onboarded = null,
    Object? verifiedGithubUsername = freezed,
    Object? verifiedGithubId = freezed,
    Object? verifiedAt = freezed,
    Object? suspendedAt = freezed,
    Object? privateMode = null,
    Object? readReceiptsEnabled = null,
    Object? publicInvestorPage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? lastActiveAt = freezed,
    Object? builderDiscipline = freezed,
    Object? builderSeniority = freezed,
    Object? builderSkills = null,
    Object? builderOpenTo = null,
    Object? builderRateBand = freezed,
    Object? founderStage = freezed,
    Object? founderSector = freezed,
    Object? founderFunding = freezed,
    Object? founderHiring = freezed,
    Object? investorType = freezed,
    Object? investorCheckSize = freezed,
    Object? investorSectors = null,
    Object? investorStage = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      handle: freezed == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      goalType: freezed == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as String?,
      goalText: freezed == goalText
          ? _value.goalText
          : goalText // ignore: cast_nullable_to_non_nullable
              as String?,
      goalUpdatedAt: freezed == goalUpdatedAt
          ? _value.goalUpdatedAt
          : goalUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      onboarded: null == onboarded
          ? _value.onboarded
          : onboarded // ignore: cast_nullable_to_non_nullable
              as bool,
      verifiedGithubUsername: freezed == verifiedGithubUsername
          ? _value.verifiedGithubUsername
          : verifiedGithubUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      verifiedGithubId: freezed == verifiedGithubId
          ? _value.verifiedGithubId
          : verifiedGithubId // ignore: cast_nullable_to_non_nullable
              as int?,
      verifiedAt: freezed == verifiedAt
          ? _value.verifiedAt
          : verifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      suspendedAt: freezed == suspendedAt
          ? _value.suspendedAt
          : suspendedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      privateMode: null == privateMode
          ? _value.privateMode
          : privateMode // ignore: cast_nullable_to_non_nullable
              as bool,
      readReceiptsEnabled: null == readReceiptsEnabled
          ? _value.readReceiptsEnabled
          : readReceiptsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      publicInvestorPage: null == publicInvestorPage
          ? _value.publicInvestorPage
          : publicInvestorPage // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      builderDiscipline: freezed == builderDiscipline
          ? _value.builderDiscipline
          : builderDiscipline // ignore: cast_nullable_to_non_nullable
              as String?,
      builderSeniority: freezed == builderSeniority
          ? _value.builderSeniority
          : builderSeniority // ignore: cast_nullable_to_non_nullable
              as String?,
      builderSkills: null == builderSkills
          ? _value.builderSkills
          : builderSkills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      builderOpenTo: null == builderOpenTo
          ? _value.builderOpenTo
          : builderOpenTo // ignore: cast_nullable_to_non_nullable
              as List<String>,
      builderRateBand: freezed == builderRateBand
          ? _value.builderRateBand
          : builderRateBand // ignore: cast_nullable_to_non_nullable
              as String?,
      founderStage: freezed == founderStage
          ? _value.founderStage
          : founderStage // ignore: cast_nullable_to_non_nullable
              as String?,
      founderSector: freezed == founderSector
          ? _value.founderSector
          : founderSector // ignore: cast_nullable_to_non_nullable
              as String?,
      founderFunding: freezed == founderFunding
          ? _value.founderFunding
          : founderFunding // ignore: cast_nullable_to_non_nullable
              as String?,
      founderHiring: freezed == founderHiring
          ? _value.founderHiring
          : founderHiring // ignore: cast_nullable_to_non_nullable
              as bool?,
      investorType: freezed == investorType
          ? _value.investorType
          : investorType // ignore: cast_nullable_to_non_nullable
              as String?,
      investorCheckSize: freezed == investorCheckSize
          ? _value.investorCheckSize
          : investorCheckSize // ignore: cast_nullable_to_non_nullable
              as String?,
      investorSectors: null == investorSectors
          ? _value.investorSectors
          : investorSectors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      investorStage: freezed == investorStage
          ? _value.investorStage
          : investorStage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
          _$ProfileImpl value, $Res Function(_$ProfileImpl) then) =
      __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? handle,
      String? name,
      String? headline,
      String? bio,
      List<String> roles,
      @JsonKey(name: 'primary_role') String? primaryRole,
      String? city,
      String? country,
      @JsonKey(name: 'goal_type') String? goalType,
      @JsonKey(name: 'goal_text') String? goalText,
      @JsonKey(name: 'goal_updated_at') DateTime? goalUpdatedAt,
      @JsonKey(name: 'photo_url') String? photoUrl,
      bool onboarded,
      @JsonKey(name: 'verified_github_username') String? verifiedGithubUsername,
      @JsonKey(name: 'verified_github_id') int? verifiedGithubId,
      @JsonKey(name: 'verified_at') DateTime? verifiedAt,
      @JsonKey(name: 'suspended_at') DateTime? suspendedAt,
      @JsonKey(name: 'private_mode') bool privateMode,
      @JsonKey(name: 'read_receipts_enabled') bool readReceiptsEnabled,
      @JsonKey(name: 'public_investor_page') bool publicInvestorPage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
      @JsonKey(name: 'builder_discipline') String? builderDiscipline,
      @JsonKey(name: 'builder_seniority') String? builderSeniority,
      @JsonKey(name: 'builder_skills') List<String> builderSkills,
      @JsonKey(name: 'builder_open_to') List<String> builderOpenTo,
      @JsonKey(name: 'builder_rate_band') String? builderRateBand,
      @JsonKey(name: 'founder_stage') String? founderStage,
      @JsonKey(name: 'founder_sector') String? founderSector,
      @JsonKey(name: 'founder_funding') String? founderFunding,
      @JsonKey(name: 'founder_hiring') bool? founderHiring,
      @JsonKey(name: 'investor_type') String? investorType,
      @JsonKey(name: 'investor_check_size') String? investorCheckSize,
      @JsonKey(name: 'investor_sectors') List<String> investorSectors,
      @JsonKey(name: 'investor_stage') String? investorStage});
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
      _$ProfileImpl _value, $Res Function(_$ProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = freezed,
    Object? name = freezed,
    Object? headline = freezed,
    Object? bio = freezed,
    Object? roles = null,
    Object? primaryRole = freezed,
    Object? city = freezed,
    Object? country = freezed,
    Object? goalType = freezed,
    Object? goalText = freezed,
    Object? goalUpdatedAt = freezed,
    Object? photoUrl = freezed,
    Object? onboarded = null,
    Object? verifiedGithubUsername = freezed,
    Object? verifiedGithubId = freezed,
    Object? verifiedAt = freezed,
    Object? suspendedAt = freezed,
    Object? privateMode = null,
    Object? readReceiptsEnabled = null,
    Object? publicInvestorPage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? lastActiveAt = freezed,
    Object? builderDiscipline = freezed,
    Object? builderSeniority = freezed,
    Object? builderSkills = null,
    Object? builderOpenTo = null,
    Object? builderRateBand = freezed,
    Object? founderStage = freezed,
    Object? founderSector = freezed,
    Object? founderFunding = freezed,
    Object? founderHiring = freezed,
    Object? investorType = freezed,
    Object? investorCheckSize = freezed,
    Object? investorSectors = null,
    Object? investorStage = freezed,
  }) {
    return _then(_$ProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      handle: freezed == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      goalType: freezed == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as String?,
      goalText: freezed == goalText
          ? _value.goalText
          : goalText // ignore: cast_nullable_to_non_nullable
              as String?,
      goalUpdatedAt: freezed == goalUpdatedAt
          ? _value.goalUpdatedAt
          : goalUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      onboarded: null == onboarded
          ? _value.onboarded
          : onboarded // ignore: cast_nullable_to_non_nullable
              as bool,
      verifiedGithubUsername: freezed == verifiedGithubUsername
          ? _value.verifiedGithubUsername
          : verifiedGithubUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      verifiedGithubId: freezed == verifiedGithubId
          ? _value.verifiedGithubId
          : verifiedGithubId // ignore: cast_nullable_to_non_nullable
              as int?,
      verifiedAt: freezed == verifiedAt
          ? _value.verifiedAt
          : verifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      suspendedAt: freezed == suspendedAt
          ? _value.suspendedAt
          : suspendedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      privateMode: null == privateMode
          ? _value.privateMode
          : privateMode // ignore: cast_nullable_to_non_nullable
              as bool,
      readReceiptsEnabled: null == readReceiptsEnabled
          ? _value.readReceiptsEnabled
          : readReceiptsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      publicInvestorPage: null == publicInvestorPage
          ? _value.publicInvestorPage
          : publicInvestorPage // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      builderDiscipline: freezed == builderDiscipline
          ? _value.builderDiscipline
          : builderDiscipline // ignore: cast_nullable_to_non_nullable
              as String?,
      builderSeniority: freezed == builderSeniority
          ? _value.builderSeniority
          : builderSeniority // ignore: cast_nullable_to_non_nullable
              as String?,
      builderSkills: null == builderSkills
          ? _value._builderSkills
          : builderSkills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      builderOpenTo: null == builderOpenTo
          ? _value._builderOpenTo
          : builderOpenTo // ignore: cast_nullable_to_non_nullable
              as List<String>,
      builderRateBand: freezed == builderRateBand
          ? _value.builderRateBand
          : builderRateBand // ignore: cast_nullable_to_non_nullable
              as String?,
      founderStage: freezed == founderStage
          ? _value.founderStage
          : founderStage // ignore: cast_nullable_to_non_nullable
              as String?,
      founderSector: freezed == founderSector
          ? _value.founderSector
          : founderSector // ignore: cast_nullable_to_non_nullable
              as String?,
      founderFunding: freezed == founderFunding
          ? _value.founderFunding
          : founderFunding // ignore: cast_nullable_to_non_nullable
              as String?,
      founderHiring: freezed == founderHiring
          ? _value.founderHiring
          : founderHiring // ignore: cast_nullable_to_non_nullable
              as bool?,
      investorType: freezed == investorType
          ? _value.investorType
          : investorType // ignore: cast_nullable_to_non_nullable
              as String?,
      investorCheckSize: freezed == investorCheckSize
          ? _value.investorCheckSize
          : investorCheckSize // ignore: cast_nullable_to_non_nullable
              as String?,
      investorSectors: null == investorSectors
          ? _value._investorSectors
          : investorSectors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      investorStage: freezed == investorStage
          ? _value.investorStage
          : investorStage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl extends _Profile {
  const _$ProfileImpl(
      {required this.id,
      this.handle,
      this.name,
      this.headline,
      this.bio,
      final List<String> roles = const <String>[],
      @JsonKey(name: 'primary_role') this.primaryRole,
      this.city,
      this.country,
      @JsonKey(name: 'goal_type') this.goalType,
      @JsonKey(name: 'goal_text') this.goalText,
      @JsonKey(name: 'goal_updated_at') this.goalUpdatedAt,
      @JsonKey(name: 'photo_url') this.photoUrl,
      this.onboarded = false,
      @JsonKey(name: 'verified_github_username') this.verifiedGithubUsername,
      @JsonKey(name: 'verified_github_id') this.verifiedGithubId,
      @JsonKey(name: 'verified_at') this.verifiedAt,
      @JsonKey(name: 'suspended_at') this.suspendedAt,
      @JsonKey(name: 'private_mode') this.privateMode = false,
      @JsonKey(name: 'read_receipts_enabled') this.readReceiptsEnabled = false,
      @JsonKey(name: 'public_investor_page') this.publicInvestorPage = false,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'last_active_at') this.lastActiveAt,
      @JsonKey(name: 'builder_discipline') this.builderDiscipline,
      @JsonKey(name: 'builder_seniority') this.builderSeniority,
      @JsonKey(name: 'builder_skills')
      final List<String> builderSkills = const <String>[],
      @JsonKey(name: 'builder_open_to')
      final List<String> builderOpenTo = const <String>[],
      @JsonKey(name: 'builder_rate_band') this.builderRateBand,
      @JsonKey(name: 'founder_stage') this.founderStage,
      @JsonKey(name: 'founder_sector') this.founderSector,
      @JsonKey(name: 'founder_funding') this.founderFunding,
      @JsonKey(name: 'founder_hiring') this.founderHiring,
      @JsonKey(name: 'investor_type') this.investorType,
      @JsonKey(name: 'investor_check_size') this.investorCheckSize,
      @JsonKey(name: 'investor_sectors')
      final List<String> investorSectors = const <String>[],
      @JsonKey(name: 'investor_stage') this.investorStage})
      : _roles = roles,
        _builderSkills = builderSkills,
        _builderOpenTo = builderOpenTo,
        _investorSectors = investorSectors,
        super._();

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String? handle;
  @override
  final String? name;
  @override
  final String? headline;
  @override
  final String? bio;
  final List<String> _roles;
  @override
  @JsonKey()
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  @JsonKey(name: 'primary_role')
  final String? primaryRole;
  @override
  final String? city;
  @override
  final String? country;
  @override
  @JsonKey(name: 'goal_type')
  final String? goalType;
  @override
  @JsonKey(name: 'goal_text')
  final String? goalText;
  @override
  @JsonKey(name: 'goal_updated_at')
  final DateTime? goalUpdatedAt;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @override
  @JsonKey()
  final bool onboarded;
  @override
  @JsonKey(name: 'verified_github_username')
  final String? verifiedGithubUsername;
  @override
  @JsonKey(name: 'verified_github_id')
  final int? verifiedGithubId;
  @override
  @JsonKey(name: 'verified_at')
  final DateTime? verifiedAt;
  @override
  @JsonKey(name: 'suspended_at')
  final DateTime? suspendedAt;
  @override
  @JsonKey(name: 'private_mode')
  final bool privateMode;
  @override
  @JsonKey(name: 'read_receipts_enabled')
  final bool readReceiptsEnabled;
  @override
  @JsonKey(name: 'public_investor_page')
  final bool publicInvestorPage;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'last_active_at')
  final DateTime? lastActiveAt;
// Role-specific structured details (spec §3a). All optional; the profile
// screen renders only the rows that resolve to a non-null value.
// Builder details
  @override
  @JsonKey(name: 'builder_discipline')
  final String? builderDiscipline;
  @override
  @JsonKey(name: 'builder_seniority')
  final String? builderSeniority;
  final List<String> _builderSkills;
  @override
  @JsonKey(name: 'builder_skills')
  List<String> get builderSkills {
    if (_builderSkills is EqualUnmodifiableListView) return _builderSkills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_builderSkills);
  }

  final List<String> _builderOpenTo;
  @override
  @JsonKey(name: 'builder_open_to')
  List<String> get builderOpenTo {
    if (_builderOpenTo is EqualUnmodifiableListView) return _builderOpenTo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_builderOpenTo);
  }

  @override
  @JsonKey(name: 'builder_rate_band')
  final String? builderRateBand;
// Founder details
  @override
  @JsonKey(name: 'founder_stage')
  final String? founderStage;
  @override
  @JsonKey(name: 'founder_sector')
  final String? founderSector;
  @override
  @JsonKey(name: 'founder_funding')
  final String? founderFunding;
  @override
  @JsonKey(name: 'founder_hiring')
  final bool? founderHiring;
// Investor details
  @override
  @JsonKey(name: 'investor_type')
  final String? investorType;
  @override
  @JsonKey(name: 'investor_check_size')
  final String? investorCheckSize;
  final List<String> _investorSectors;
  @override
  @JsonKey(name: 'investor_sectors')
  List<String> get investorSectors {
    if (_investorSectors is EqualUnmodifiableListView) return _investorSectors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_investorSectors);
  }

  @override
  @JsonKey(name: 'investor_stage')
  final String? investorStage;

  @override
  String toString() {
    return 'Profile(id: $id, handle: $handle, name: $name, headline: $headline, bio: $bio, roles: $roles, primaryRole: $primaryRole, city: $city, country: $country, goalType: $goalType, goalText: $goalText, goalUpdatedAt: $goalUpdatedAt, photoUrl: $photoUrl, onboarded: $onboarded, verifiedGithubUsername: $verifiedGithubUsername, verifiedGithubId: $verifiedGithubId, verifiedAt: $verifiedAt, suspendedAt: $suspendedAt, privateMode: $privateMode, readReceiptsEnabled: $readReceiptsEnabled, publicInvestorPage: $publicInvestorPage, createdAt: $createdAt, updatedAt: $updatedAt, lastActiveAt: $lastActiveAt, builderDiscipline: $builderDiscipline, builderSeniority: $builderSeniority, builderSkills: $builderSkills, builderOpenTo: $builderOpenTo, builderRateBand: $builderRateBand, founderStage: $founderStage, founderSector: $founderSector, founderFunding: $founderFunding, founderHiring: $founderHiring, investorType: $investorType, investorCheckSize: $investorCheckSize, investorSectors: $investorSectors, investorStage: $investorStage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.headline, headline) ||
                other.headline == headline) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.primaryRole, primaryRole) ||
                other.primaryRole == primaryRole) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.goalType, goalType) ||
                other.goalType == goalType) &&
            (identical(other.goalText, goalText) ||
                other.goalText == goalText) &&
            (identical(other.goalUpdatedAt, goalUpdatedAt) ||
                other.goalUpdatedAt == goalUpdatedAt) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.onboarded, onboarded) ||
                other.onboarded == onboarded) &&
            (identical(other.verifiedGithubUsername, verifiedGithubUsername) ||
                other.verifiedGithubUsername == verifiedGithubUsername) &&
            (identical(other.verifiedGithubId, verifiedGithubId) ||
                other.verifiedGithubId == verifiedGithubId) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt) &&
            (identical(other.suspendedAt, suspendedAt) ||
                other.suspendedAt == suspendedAt) &&
            (identical(other.privateMode, privateMode) ||
                other.privateMode == privateMode) &&
            (identical(other.readReceiptsEnabled, readReceiptsEnabled) ||
                other.readReceiptsEnabled == readReceiptsEnabled) &&
            (identical(other.publicInvestorPage, publicInvestorPage) ||
                other.publicInvestorPage == publicInvestorPage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.builderDiscipline, builderDiscipline) ||
                other.builderDiscipline == builderDiscipline) &&
            (identical(other.builderSeniority, builderSeniority) ||
                other.builderSeniority == builderSeniority) &&
            const DeepCollectionEquality()
                .equals(other._builderSkills, _builderSkills) &&
            const DeepCollectionEquality()
                .equals(other._builderOpenTo, _builderOpenTo) &&
            (identical(other.builderRateBand, builderRateBand) ||
                other.builderRateBand == builderRateBand) &&
            (identical(other.founderStage, founderStage) ||
                other.founderStage == founderStage) &&
            (identical(other.founderSector, founderSector) ||
                other.founderSector == founderSector) &&
            (identical(other.founderFunding, founderFunding) ||
                other.founderFunding == founderFunding) &&
            (identical(other.founderHiring, founderHiring) ||
                other.founderHiring == founderHiring) &&
            (identical(other.investorType, investorType) ||
                other.investorType == investorType) &&
            (identical(other.investorCheckSize, investorCheckSize) ||
                other.investorCheckSize == investorCheckSize) &&
            const DeepCollectionEquality()
                .equals(other._investorSectors, _investorSectors) &&
            (identical(other.investorStage, investorStage) ||
                other.investorStage == investorStage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        handle,
        name,
        headline,
        bio,
        const DeepCollectionEquality().hash(_roles),
        primaryRole,
        city,
        country,
        goalType,
        goalText,
        goalUpdatedAt,
        photoUrl,
        onboarded,
        verifiedGithubUsername,
        verifiedGithubId,
        verifiedAt,
        suspendedAt,
        privateMode,
        readReceiptsEnabled,
        publicInvestorPage,
        createdAt,
        updatedAt,
        lastActiveAt,
        builderDiscipline,
        builderSeniority,
        const DeepCollectionEquality().hash(_builderSkills),
        const DeepCollectionEquality().hash(_builderOpenTo),
        builderRateBand,
        founderStage,
        founderSector,
        founderFunding,
        founderHiring,
        investorType,
        investorCheckSize,
        const DeepCollectionEquality().hash(_investorSectors),
        investorStage
      ]);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(
      this,
    );
  }
}

abstract class _Profile extends Profile {
  const factory _Profile(
      {required final String id,
      final String? handle,
      final String? name,
      final String? headline,
      final String? bio,
      final List<String> roles,
      @JsonKey(name: 'primary_role') final String? primaryRole,
      final String? city,
      final String? country,
      @JsonKey(name: 'goal_type') final String? goalType,
      @JsonKey(name: 'goal_text') final String? goalText,
      @JsonKey(name: 'goal_updated_at') final DateTime? goalUpdatedAt,
      @JsonKey(name: 'photo_url') final String? photoUrl,
      final bool onboarded,
      @JsonKey(name: 'verified_github_username')
      final String? verifiedGithubUsername,
      @JsonKey(name: 'verified_github_id') final int? verifiedGithubId,
      @JsonKey(name: 'verified_at') final DateTime? verifiedAt,
      @JsonKey(name: 'suspended_at') final DateTime? suspendedAt,
      @JsonKey(name: 'private_mode') final bool privateMode,
      @JsonKey(name: 'read_receipts_enabled') final bool readReceiptsEnabled,
      @JsonKey(name: 'public_investor_page') final bool publicInvestorPage,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt,
      @JsonKey(name: 'last_active_at') final DateTime? lastActiveAt,
      @JsonKey(name: 'builder_discipline') final String? builderDiscipline,
      @JsonKey(name: 'builder_seniority') final String? builderSeniority,
      @JsonKey(name: 'builder_skills') final List<String> builderSkills,
      @JsonKey(name: 'builder_open_to') final List<String> builderOpenTo,
      @JsonKey(name: 'builder_rate_band') final String? builderRateBand,
      @JsonKey(name: 'founder_stage') final String? founderStage,
      @JsonKey(name: 'founder_sector') final String? founderSector,
      @JsonKey(name: 'founder_funding') final String? founderFunding,
      @JsonKey(name: 'founder_hiring') final bool? founderHiring,
      @JsonKey(name: 'investor_type') final String? investorType,
      @JsonKey(name: 'investor_check_size') final String? investorCheckSize,
      @JsonKey(name: 'investor_sectors') final List<String> investorSectors,
      @JsonKey(name: 'investor_stage')
      final String? investorStage}) = _$ProfileImpl;
  const _Profile._() : super._();

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  String get id;
  @override
  String? get handle;
  @override
  String? get name;
  @override
  String? get headline;
  @override
  String? get bio;
  @override
  List<String> get roles;
  @override
  @JsonKey(name: 'primary_role')
  String? get primaryRole;
  @override
  String? get city;
  @override
  String? get country;
  @override
  @JsonKey(name: 'goal_type')
  String? get goalType;
  @override
  @JsonKey(name: 'goal_text')
  String? get goalText;
  @override
  @JsonKey(name: 'goal_updated_at')
  DateTime? get goalUpdatedAt;
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @override
  bool get onboarded;
  @override
  @JsonKey(name: 'verified_github_username')
  String? get verifiedGithubUsername;
  @override
  @JsonKey(name: 'verified_github_id')
  int? get verifiedGithubId;
  @override
  @JsonKey(name: 'verified_at')
  DateTime? get verifiedAt;
  @override
  @JsonKey(name: 'suspended_at')
  DateTime? get suspendedAt;
  @override
  @JsonKey(name: 'private_mode')
  bool get privateMode;
  @override
  @JsonKey(name: 'read_receipts_enabled')
  bool get readReceiptsEnabled;
  @override
  @JsonKey(name: 'public_investor_page')
  bool get publicInvestorPage;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'last_active_at')
  DateTime?
      get lastActiveAt; // Role-specific structured details (spec §3a). All optional; the profile
// screen renders only the rows that resolve to a non-null value.
// Builder details
  @override
  @JsonKey(name: 'builder_discipline')
  String? get builderDiscipline;
  @override
  @JsonKey(name: 'builder_seniority')
  String? get builderSeniority;
  @override
  @JsonKey(name: 'builder_skills')
  List<String> get builderSkills;
  @override
  @JsonKey(name: 'builder_open_to')
  List<String> get builderOpenTo;
  @override
  @JsonKey(name: 'builder_rate_band')
  String? get builderRateBand; // Founder details
  @override
  @JsonKey(name: 'founder_stage')
  String? get founderStage;
  @override
  @JsonKey(name: 'founder_sector')
  String? get founderSector;
  @override
  @JsonKey(name: 'founder_funding')
  String? get founderFunding;
  @override
  @JsonKey(name: 'founder_hiring')
  bool? get founderHiring; // Investor details
  @override
  @JsonKey(name: 'investor_type')
  String? get investorType;
  @override
  @JsonKey(name: 'investor_check_size')
  String? get investorCheckSize;
  @override
  @JsonKey(name: 'investor_sectors')
  List<String> get investorSectors;
  @override
  @JsonKey(name: 'investor_stage')
  String? get investorStage;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

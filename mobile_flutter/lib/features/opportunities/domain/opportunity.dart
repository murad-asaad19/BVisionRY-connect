import 'package:freezed_annotation/freezed_annotation.dart';

import 'opportunity_kind.dart';
import 'opportunity_status.dart';

part 'opportunity.freezed.dart';
part 'opportunity.g.dart';

OpportunityKind _kindFromJson(String v) => OpportunityKind.fromDb(v);
String _kindToJson(OpportunityKind k) => k.dbValue;
OpportunityStatus _statusFromJson(String v) => OpportunityStatus.fromDb(v);
String _statusToJson(OpportunityStatus s) => s.dbValue;
List<String> _tagsFromJson(Object? v) =>
    v is List ? List<String>.from(v) : const <String>[];
DateTime _utcFromJson(Object v) => DateTime.parse(v as String).toUtc();
String _utcToJson(DateTime v) => v.toUtc().toIso8601String();
DateTime? _utcFromJsonNullable(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();
String? _utcToJsonNullable(DateTime? v) => v?.toUtc().toIso8601String();

/// One row of `public.opportunities` (spec §2.18).
///
/// All timestamps are kept in UTC; the UI layer converts to local time for
/// display.
@freezed
class Opportunity with _$Opportunity {
  const factory Opportunity({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
    required OpportunityKind kind,
    required String title,
    required String body,
    @JsonKey(fromJson: _tagsFromJson) required List<String> tags,
    @JsonKey(name: 'location_city') String? locationCity,
    @JsonKey(name: 'location_country') String? locationCountry,
    @JsonKey(name: 'remote_ok') required bool remoteOk,
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
    required OpportunityStatus status,
    @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
    required DateTime expiresAt,
    @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
    required DateTime createdAt,
    @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
    required DateTime updatedAt,
    @JsonKey(
      name: 'closed_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable,
    )
    DateTime? closedAt,
  }) = _Opportunity;

  factory Opportunity.fromJson(Map<String, dynamic> json) =>
      _$OpportunityFromJson(json);
}

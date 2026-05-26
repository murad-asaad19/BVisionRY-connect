import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_booking.freezed.dart';
part 'my_booking.g.dart';

DateTime _utcFromJson(Object v) => DateTime.parse(v as String).toUtc();
String _utcToJson(DateTime v) => v.toUtc().toIso8601String();

/// One row of `my_bookings()` (spec §3.6) — a future booking the caller
/// holds against another user's office hours.
///
/// Powers the My Bookings list: tap a card to open the canonical chat
/// (via [meetingProposalId] resolved to a conversation), or Cancel to call
/// `cancel_booking`. The 24-hour reopen-vs-cancel rule is centralized
/// here in [willReopenOnCancel] so the UI can render the confirm body
/// accurately.
@freezed
class MyBooking with _$MyBooking {
  const factory MyBooking({
    @JsonKey(name: 'slot_id') required String slotId,
    @JsonKey(name: 'host_id') required String hostId,
    @JsonKey(name: 'host_handle') required String hostHandle,
    @JsonKey(name: 'host_name') required String hostName,
    @JsonKey(name: 'host_photo_url') String? hostPhotoUrl,
    @JsonKey(
      name: 'starts_at',
      fromJson: _utcFromJson,
      toJson: _utcToJson,
    )
    required DateTime startsAt,
    @JsonKey(
      name: 'ends_at',
      fromJson: _utcFromJson,
      toJson: _utcToJson,
    )
    required DateTime endsAt,
    String? topic,
    @JsonKey(name: 'meeting_proposal_id') String? meetingProposalId,
  }) = _MyBooking;

  const MyBooking._();

  factory MyBooking.fromJson(Map<String, dynamic> json) =>
      _$MyBookingFromJson(json);

  int get durationMinutes => endsAt.difference(startsAt).inMinutes;

  /// Cancellation policy: when the slot starts more than 24h from now, the
  /// server reopens it for someone else; otherwise it just cancels in place.
  bool willReopenOnCancel({DateTime? now}) => startsAt
      .isAfter((now ?? DateTime.now().toUtc()).add(const Duration(hours: 24)));
}

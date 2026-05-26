// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opportunity_with_counts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OpportunityWithCounts {
  OpportunityWithAuthor get withAuthor => throw _privateConstructorUsedError;
  int get interestedCount => throw _privateConstructorUsedError;
  bool get viewerHasExpressedInterest => throw _privateConstructorUsedError;

  /// Create a copy of OpportunityWithCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpportunityWithCountsCopyWith<OpportunityWithCounts> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpportunityWithCountsCopyWith<$Res> {
  factory $OpportunityWithCountsCopyWith(OpportunityWithCounts value,
          $Res Function(OpportunityWithCounts) then) =
      _$OpportunityWithCountsCopyWithImpl<$Res, OpportunityWithCounts>;
  @useResult
  $Res call(
      {OpportunityWithAuthor withAuthor,
      int interestedCount,
      bool viewerHasExpressedInterest});

  $OpportunityWithAuthorCopyWith<$Res> get withAuthor;
}

/// @nodoc
class _$OpportunityWithCountsCopyWithImpl<$Res,
        $Val extends OpportunityWithCounts>
    implements $OpportunityWithCountsCopyWith<$Res> {
  _$OpportunityWithCountsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpportunityWithCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? withAuthor = null,
    Object? interestedCount = null,
    Object? viewerHasExpressedInterest = null,
  }) {
    return _then(_value.copyWith(
      withAuthor: null == withAuthor
          ? _value.withAuthor
          : withAuthor // ignore: cast_nullable_to_non_nullable
              as OpportunityWithAuthor,
      interestedCount: null == interestedCount
          ? _value.interestedCount
          : interestedCount // ignore: cast_nullable_to_non_nullable
              as int,
      viewerHasExpressedInterest: null == viewerHasExpressedInterest
          ? _value.viewerHasExpressedInterest
          : viewerHasExpressedInterest // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of OpportunityWithCounts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OpportunityWithAuthorCopyWith<$Res> get withAuthor {
    return $OpportunityWithAuthorCopyWith<$Res>(_value.withAuthor, (value) {
      return _then(_value.copyWith(withAuthor: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OpportunityWithCountsImplCopyWith<$Res>
    implements $OpportunityWithCountsCopyWith<$Res> {
  factory _$$OpportunityWithCountsImplCopyWith(
          _$OpportunityWithCountsImpl value,
          $Res Function(_$OpportunityWithCountsImpl) then) =
      __$$OpportunityWithCountsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {OpportunityWithAuthor withAuthor,
      int interestedCount,
      bool viewerHasExpressedInterest});

  @override
  $OpportunityWithAuthorCopyWith<$Res> get withAuthor;
}

/// @nodoc
class __$$OpportunityWithCountsImplCopyWithImpl<$Res>
    extends _$OpportunityWithCountsCopyWithImpl<$Res,
        _$OpportunityWithCountsImpl>
    implements _$$OpportunityWithCountsImplCopyWith<$Res> {
  __$$OpportunityWithCountsImplCopyWithImpl(_$OpportunityWithCountsImpl _value,
      $Res Function(_$OpportunityWithCountsImpl) _then)
      : super(_value, _then);

  /// Create a copy of OpportunityWithCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? withAuthor = null,
    Object? interestedCount = null,
    Object? viewerHasExpressedInterest = null,
  }) {
    return _then(_$OpportunityWithCountsImpl(
      withAuthor: null == withAuthor
          ? _value.withAuthor
          : withAuthor // ignore: cast_nullable_to_non_nullable
              as OpportunityWithAuthor,
      interestedCount: null == interestedCount
          ? _value.interestedCount
          : interestedCount // ignore: cast_nullable_to_non_nullable
              as int,
      viewerHasExpressedInterest: null == viewerHasExpressedInterest
          ? _value.viewerHasExpressedInterest
          : viewerHasExpressedInterest // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$OpportunityWithCountsImpl extends _OpportunityWithCounts {
  const _$OpportunityWithCountsImpl(
      {required this.withAuthor,
      required this.interestedCount,
      required this.viewerHasExpressedInterest})
      : super._();

  @override
  final OpportunityWithAuthor withAuthor;
  @override
  final int interestedCount;
  @override
  final bool viewerHasExpressedInterest;

  @override
  String toString() {
    return 'OpportunityWithCounts(withAuthor: $withAuthor, interestedCount: $interestedCount, viewerHasExpressedInterest: $viewerHasExpressedInterest)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpportunityWithCountsImpl &&
            (identical(other.withAuthor, withAuthor) ||
                other.withAuthor == withAuthor) &&
            (identical(other.interestedCount, interestedCount) ||
                other.interestedCount == interestedCount) &&
            (identical(other.viewerHasExpressedInterest,
                    viewerHasExpressedInterest) ||
                other.viewerHasExpressedInterest ==
                    viewerHasExpressedInterest));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, withAuthor, interestedCount, viewerHasExpressedInterest);

  /// Create a copy of OpportunityWithCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpportunityWithCountsImplCopyWith<_$OpportunityWithCountsImpl>
      get copyWith => __$$OpportunityWithCountsImplCopyWithImpl<
          _$OpportunityWithCountsImpl>(this, _$identity);
}

abstract class _OpportunityWithCounts extends OpportunityWithCounts {
  const factory _OpportunityWithCounts(
          {required final OpportunityWithAuthor withAuthor,
          required final int interestedCount,
          required final bool viewerHasExpressedInterest}) =
      _$OpportunityWithCountsImpl;
  const _OpportunityWithCounts._() : super._();

  @override
  OpportunityWithAuthor get withAuthor;
  @override
  int get interestedCount;
  @override
  bool get viewerHasExpressedInterest;

  /// Create a copy of OpportunityWithCounts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpportunityWithCountsImplCopyWith<_$OpportunityWithCountsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

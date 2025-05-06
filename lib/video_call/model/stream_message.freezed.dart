// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreamMessage {

 String? get id; String? get stream_id; String? get user_id; String? get message; DateTime? get created_at; Account? get user;
/// Create a copy of StreamMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamMessageCopyWith<StreamMessage> get copyWith => _$StreamMessageCopyWithImpl<StreamMessage>(this as StreamMessage, _$identity);

  /// Serializes this StreamMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.stream_id, stream_id) || other.stream_id == stream_id)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.message, message) || other.message == message)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stream_id,user_id,message,created_at,user);

@override
String toString() {
  return 'StreamMessage(id: $id, stream_id: $stream_id, user_id: $user_id, message: $message, created_at: $created_at, user: $user)';
}


}

/// @nodoc
abstract mixin class $StreamMessageCopyWith<$Res>  {
  factory $StreamMessageCopyWith(StreamMessage value, $Res Function(StreamMessage) _then) = _$StreamMessageCopyWithImpl;
@useResult
$Res call({
 String? id, String? stream_id, String? user_id, String? message, DateTime? created_at, Account? user
});


$AccountCopyWith<$Res>? get user;

}
/// @nodoc
class _$StreamMessageCopyWithImpl<$Res>
    implements $StreamMessageCopyWith<$Res> {
  _$StreamMessageCopyWithImpl(this._self, this._then);

  final StreamMessage _self;
  final $Res Function(StreamMessage) _then;

/// Create a copy of StreamMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? stream_id = freezed,Object? user_id = freezed,Object? message = freezed,Object? created_at = freezed,Object? user = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,stream_id: freezed == stream_id ? _self.stream_id : stream_id // ignore: cast_nullable_to_non_nullable
as String?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as Account?,
  ));
}
/// Create a copy of StreamMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AccountCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _StreamMessage implements StreamMessage {
  const _StreamMessage({required this.id, required this.stream_id, required this.user_id, required this.message, required this.created_at, this.user});
  factory _StreamMessage.fromJson(Map<String, dynamic> json) => _$StreamMessageFromJson(json);

@override final  String? id;
@override final  String? stream_id;
@override final  String? user_id;
@override final  String? message;
@override final  DateTime? created_at;
@override final  Account? user;

/// Create a copy of StreamMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamMessageCopyWith<_StreamMessage> get copyWith => __$StreamMessageCopyWithImpl<_StreamMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.stream_id, stream_id) || other.stream_id == stream_id)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.message, message) || other.message == message)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stream_id,user_id,message,created_at,user);

@override
String toString() {
  return 'StreamMessage(id: $id, stream_id: $stream_id, user_id: $user_id, message: $message, created_at: $created_at, user: $user)';
}


}

/// @nodoc
abstract mixin class _$StreamMessageCopyWith<$Res> implements $StreamMessageCopyWith<$Res> {
  factory _$StreamMessageCopyWith(_StreamMessage value, $Res Function(_StreamMessage) _then) = __$StreamMessageCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? stream_id, String? user_id, String? message, DateTime? created_at, Account? user
});


@override $AccountCopyWith<$Res>? get user;

}
/// @nodoc
class __$StreamMessageCopyWithImpl<$Res>
    implements _$StreamMessageCopyWith<$Res> {
  __$StreamMessageCopyWithImpl(this._self, this._then);

  final _StreamMessage _self;
  final $Res Function(_StreamMessage) _then;

/// Create a copy of StreamMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? stream_id = freezed,Object? user_id = freezed,Object? message = freezed,Object? created_at = freezed,Object? user = freezed,}) {
  return _then(_StreamMessage(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,stream_id: freezed == stream_id ? _self.stream_id : stream_id // ignore: cast_nullable_to_non_nullable
as String?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as Account?,
  ));
}

/// Create a copy of StreamMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AccountCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on

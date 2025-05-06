// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_stream.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveStream {

 String? get id; String? get user_id; String? get title; String? get description; String? get channel_name; DateTime? get created_at; DateTime? get ended_at; bool? get is_active; bool? get has_host_connected;// Add this field
 DateTime? get host_disconnected_at;// Add this field
 String? get thumbnail_url; int? get viewer_count; Account? get user;
/// Create a copy of LiveStream
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveStreamCopyWith<LiveStream> get copyWith => _$LiveStreamCopyWithImpl<LiveStream>(this as LiveStream, _$identity);

  /// Serializes this LiveStream to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveStream&&(identical(other.id, id) || other.id == id)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.channel_name, channel_name) || other.channel_name == channel_name)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.ended_at, ended_at) || other.ended_at == ended_at)&&(identical(other.is_active, is_active) || other.is_active == is_active)&&(identical(other.has_host_connected, has_host_connected) || other.has_host_connected == has_host_connected)&&(identical(other.host_disconnected_at, host_disconnected_at) || other.host_disconnected_at == host_disconnected_at)&&(identical(other.thumbnail_url, thumbnail_url) || other.thumbnail_url == thumbnail_url)&&(identical(other.viewer_count, viewer_count) || other.viewer_count == viewer_count)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,user_id,title,description,channel_name,created_at,ended_at,is_active,has_host_connected,host_disconnected_at,thumbnail_url,viewer_count,user);

@override
String toString() {
  return 'LiveStream(id: $id, user_id: $user_id, title: $title, description: $description, channel_name: $channel_name, created_at: $created_at, ended_at: $ended_at, is_active: $is_active, has_host_connected: $has_host_connected, host_disconnected_at: $host_disconnected_at, thumbnail_url: $thumbnail_url, viewer_count: $viewer_count, user: $user)';
}


}

/// @nodoc
abstract mixin class $LiveStreamCopyWith<$Res>  {
  factory $LiveStreamCopyWith(LiveStream value, $Res Function(LiveStream) _then) = _$LiveStreamCopyWithImpl;
@useResult
$Res call({
 String? id, String? user_id, String? title, String? description, String? channel_name, DateTime? created_at, DateTime? ended_at, bool? is_active, bool? has_host_connected, DateTime? host_disconnected_at, String? thumbnail_url, int? viewer_count, Account? user
});


$AccountCopyWith<$Res>? get user;

}
/// @nodoc
class _$LiveStreamCopyWithImpl<$Res>
    implements $LiveStreamCopyWith<$Res> {
  _$LiveStreamCopyWithImpl(this._self, this._then);

  final LiveStream _self;
  final $Res Function(LiveStream) _then;

/// Create a copy of LiveStream
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? user_id = freezed,Object? title = freezed,Object? description = freezed,Object? channel_name = freezed,Object? created_at = freezed,Object? ended_at = freezed,Object? is_active = freezed,Object? has_host_connected = freezed,Object? host_disconnected_at = freezed,Object? thumbnail_url = freezed,Object? viewer_count = freezed,Object? user = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,channel_name: freezed == channel_name ? _self.channel_name : channel_name // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,ended_at: freezed == ended_at ? _self.ended_at : ended_at // ignore: cast_nullable_to_non_nullable
as DateTime?,is_active: freezed == is_active ? _self.is_active : is_active // ignore: cast_nullable_to_non_nullable
as bool?,has_host_connected: freezed == has_host_connected ? _self.has_host_connected : has_host_connected // ignore: cast_nullable_to_non_nullable
as bool?,host_disconnected_at: freezed == host_disconnected_at ? _self.host_disconnected_at : host_disconnected_at // ignore: cast_nullable_to_non_nullable
as DateTime?,thumbnail_url: freezed == thumbnail_url ? _self.thumbnail_url : thumbnail_url // ignore: cast_nullable_to_non_nullable
as String?,viewer_count: freezed == viewer_count ? _self.viewer_count : viewer_count // ignore: cast_nullable_to_non_nullable
as int?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as Account?,
  ));
}
/// Create a copy of LiveStream
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

class _LiveStream implements LiveStream {
  const _LiveStream({required this.id, required this.user_id, required this.title, this.description, required this.channel_name, required this.created_at, this.ended_at, required this.is_active, required this.has_host_connected, this.host_disconnected_at, this.thumbnail_url, required this.viewer_count, this.user});
  factory _LiveStream.fromJson(Map<String, dynamic> json) => _$LiveStreamFromJson(json);

@override final  String? id;
@override final  String? user_id;
@override final  String? title;
@override final  String? description;
@override final  String? channel_name;
@override final  DateTime? created_at;
@override final  DateTime? ended_at;
@override final  bool? is_active;
@override final  bool? has_host_connected;
// Add this field
@override final  DateTime? host_disconnected_at;
// Add this field
@override final  String? thumbnail_url;
@override final  int? viewer_count;
@override final  Account? user;

/// Create a copy of LiveStream
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveStreamCopyWith<_LiveStream> get copyWith => __$LiveStreamCopyWithImpl<_LiveStream>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveStreamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveStream&&(identical(other.id, id) || other.id == id)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.channel_name, channel_name) || other.channel_name == channel_name)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.ended_at, ended_at) || other.ended_at == ended_at)&&(identical(other.is_active, is_active) || other.is_active == is_active)&&(identical(other.has_host_connected, has_host_connected) || other.has_host_connected == has_host_connected)&&(identical(other.host_disconnected_at, host_disconnected_at) || other.host_disconnected_at == host_disconnected_at)&&(identical(other.thumbnail_url, thumbnail_url) || other.thumbnail_url == thumbnail_url)&&(identical(other.viewer_count, viewer_count) || other.viewer_count == viewer_count)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,user_id,title,description,channel_name,created_at,ended_at,is_active,has_host_connected,host_disconnected_at,thumbnail_url,viewer_count,user);

@override
String toString() {
  return 'LiveStream(id: $id, user_id: $user_id, title: $title, description: $description, channel_name: $channel_name, created_at: $created_at, ended_at: $ended_at, is_active: $is_active, has_host_connected: $has_host_connected, host_disconnected_at: $host_disconnected_at, thumbnail_url: $thumbnail_url, viewer_count: $viewer_count, user: $user)';
}


}

/// @nodoc
abstract mixin class _$LiveStreamCopyWith<$Res> implements $LiveStreamCopyWith<$Res> {
  factory _$LiveStreamCopyWith(_LiveStream value, $Res Function(_LiveStream) _then) = __$LiveStreamCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? user_id, String? title, String? description, String? channel_name, DateTime? created_at, DateTime? ended_at, bool? is_active, bool? has_host_connected, DateTime? host_disconnected_at, String? thumbnail_url, int? viewer_count, Account? user
});


@override $AccountCopyWith<$Res>? get user;

}
/// @nodoc
class __$LiveStreamCopyWithImpl<$Res>
    implements _$LiveStreamCopyWith<$Res> {
  __$LiveStreamCopyWithImpl(this._self, this._then);

  final _LiveStream _self;
  final $Res Function(_LiveStream) _then;

/// Create a copy of LiveStream
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? user_id = freezed,Object? title = freezed,Object? description = freezed,Object? channel_name = freezed,Object? created_at = freezed,Object? ended_at = freezed,Object? is_active = freezed,Object? has_host_connected = freezed,Object? host_disconnected_at = freezed,Object? thumbnail_url = freezed,Object? viewer_count = freezed,Object? user = freezed,}) {
  return _then(_LiveStream(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,channel_name: freezed == channel_name ? _self.channel_name : channel_name // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,ended_at: freezed == ended_at ? _self.ended_at : ended_at // ignore: cast_nullable_to_non_nullable
as DateTime?,is_active: freezed == is_active ? _self.is_active : is_active // ignore: cast_nullable_to_non_nullable
as bool?,has_host_connected: freezed == has_host_connected ? _self.has_host_connected : has_host_connected // ignore: cast_nullable_to_non_nullable
as bool?,host_disconnected_at: freezed == host_disconnected_at ? _self.host_disconnected_at : host_disconnected_at // ignore: cast_nullable_to_non_nullable
as DateTime?,thumbnail_url: freezed == thumbnail_url ? _self.thumbnail_url : thumbnail_url // ignore: cast_nullable_to_non_nullable
as String?,viewer_count: freezed == viewer_count ? _self.viewer_count : viewer_count // ignore: cast_nullable_to_non_nullable
as int?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as Account?,
  ));
}

/// Create a copy of LiveStream
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

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Account {

 String? get id; String? get image_url; String? get image_id; String? get email; String? get username;// for an artist to be verified, they need to have at least 100 followers.
 bool? get is_verified;// check if the user is a verified artist or not
 String? get fcm_token; DateTime? get created_at;// will add a location field later
 String? get bio;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, id) || other.id == id)&&(identical(other.image_url, image_url) || other.image_url == image_url)&&(identical(other.image_id, image_id) || other.image_id == image_id)&&(identical(other.email, email) || other.email == email)&&(identical(other.username, username) || other.username == username)&&(identical(other.is_verified, is_verified) || other.is_verified == is_verified)&&(identical(other.fcm_token, fcm_token) || other.fcm_token == fcm_token)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.bio, bio) || other.bio == bio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,image_url,image_id,email,username,is_verified,fcm_token,created_at,bio);

@override
String toString() {
  return 'Account(id: $id, image_url: $image_url, image_id: $image_id, email: $email, username: $username, is_verified: $is_verified, fcm_token: $fcm_token, created_at: $created_at, bio: $bio)';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
 String? id, String? image_url, String? image_id, String? email, String? username, bool? is_verified, String? fcm_token, DateTime? created_at, String? bio
});




}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? image_url = freezed,Object? image_id = freezed,Object? email = freezed,Object? username = freezed,Object? is_verified = freezed,Object? fcm_token = freezed,Object? created_at = freezed,Object? bio = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,image_url: freezed == image_url ? _self.image_url : image_url // ignore: cast_nullable_to_non_nullable
as String?,image_id: freezed == image_id ? _self.image_id : image_id // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,is_verified: freezed == is_verified ? _self.is_verified : is_verified // ignore: cast_nullable_to_non_nullable
as bool?,fcm_token: freezed == fcm_token ? _self.fcm_token : fcm_token // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Account implements Account {
  const _Account({required this.id, required this.image_url, required this.image_id, required this.email, required this.username, this.is_verified = false, required this.fcm_token, required this.created_at, this.bio});
  factory _Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

@override final  String? id;
@override final  String? image_url;
@override final  String? image_id;
@override final  String? email;
@override final  String? username;
// for an artist to be verified, they need to have at least 100 followers.
@override@JsonKey() final  bool? is_verified;
// check if the user is a verified artist or not
@override final  String? fcm_token;
@override final  DateTime? created_at;
// will add a location field later
@override final  String? bio;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.image_url, image_url) || other.image_url == image_url)&&(identical(other.image_id, image_id) || other.image_id == image_id)&&(identical(other.email, email) || other.email == email)&&(identical(other.username, username) || other.username == username)&&(identical(other.is_verified, is_verified) || other.is_verified == is_verified)&&(identical(other.fcm_token, fcm_token) || other.fcm_token == fcm_token)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.bio, bio) || other.bio == bio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,image_url,image_id,email,username,is_verified,fcm_token,created_at,bio);

@override
String toString() {
  return 'Account(id: $id, image_url: $image_url, image_id: $image_id, email: $email, username: $username, is_verified: $is_verified, fcm_token: $fcm_token, created_at: $created_at, bio: $bio)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? image_url, String? image_id, String? email, String? username, bool? is_verified, String? fcm_token, DateTime? created_at, String? bio
});




}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? image_url = freezed,Object? image_id = freezed,Object? email = freezed,Object? username = freezed,Object? is_verified = freezed,Object? fcm_token = freezed,Object? created_at = freezed,Object? bio = freezed,}) {
  return _then(_Account(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,image_url: freezed == image_url ? _self.image_url : image_url // ignore: cast_nullable_to_non_nullable
as String?,image_id: freezed == image_id ? _self.image_id : image_id // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,is_verified: freezed == is_verified ? _self.is_verified : is_verified // ignore: cast_nullable_to_non_nullable
as bool?,fcm_token: freezed == fcm_token ? _self.fcm_token : fcm_token // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

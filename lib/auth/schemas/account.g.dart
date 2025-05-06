// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: json['id'] as String?,
  image_url: json['image_url'] as String?,
  image_id: json['image_id'] as String?,
  email: json['email'] as String?,
  username: json['username'] as String?,
  is_verified: json['is_verified'] as bool? ?? false,
  fcm_token: json['fcm_token'] as String?,
  created_at:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  bio: json['bio'] as String?,
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'image_url': instance.image_url,
  'image_id': instance.image_id,
  'email': instance.email,
  'username': instance.username,
  'is_verified': instance.is_verified,
  'fcm_token': instance.fcm_token,
  'created_at': instance.created_at?.toIso8601String(),
  'bio': instance.bio,
};

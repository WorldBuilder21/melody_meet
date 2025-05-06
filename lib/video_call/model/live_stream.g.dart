// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_stream.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveStream _$LiveStreamFromJson(Map<String, dynamic> json) => _LiveStream(
  id: json['id'] as String?,
  user_id: json['user_id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  channel_name: json['channel_name'] as String?,
  created_at:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  ended_at:
      json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
  is_active: json['is_active'] as bool?,
  thumbnail_url: json['thumbnail_url'] as String?,
  viewer_count: (json['viewer_count'] as num?)?.toInt(),
  user:
      json['user'] == null
          ? null
          : Account.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveStreamToJson(_LiveStream instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'title': instance.title,
      'description': instance.description,
      'channel_name': instance.channel_name,
      'created_at': instance.created_at?.toIso8601String(),
      'ended_at': instance.ended_at?.toIso8601String(),
      'is_active': instance.is_active,
      'thumbnail_url': instance.thumbnail_url,
      'viewer_count': instance.viewer_count,
      'user': instance.user,
    };

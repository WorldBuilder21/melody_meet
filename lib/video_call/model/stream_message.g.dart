// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StreamMessage _$StreamMessageFromJson(Map<String, dynamic> json) =>
    _StreamMessage(
      id: json['id'] as String?,
      stream_id: json['stream_id'] as String?,
      user_id: json['user_id'] as String?,
      message: json['message'] as String?,
      created_at:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      user:
          json['user'] == null
              ? null
              : Account.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StreamMessageToJson(_StreamMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stream_id': instance.stream_id,
      'user_id': instance.user_id,
      'message': instance.message,
      'created_at': instance.created_at?.toIso8601String(),
      'user': instance.user,
    };

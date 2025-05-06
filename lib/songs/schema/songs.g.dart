// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Songs _$SongsFromJson(Map<String, dynamic> json) => _Songs(
  id: json['id'] as String?,
  account_id: json['account_id'] as String?,
  title: json['title'] as String?,
  artist: json['artist'] as String?,
  created_at:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  image_url: json['image_url'] as String?,
  image_id: json['image_id'] as String?,
  audio_url: json['audio_url'] as String?,
  audio_id: json['audio_id'] as String?,
  genre: json['genre'] as String?,
  description: json['description'] as String?,
  user_id: json['user_id'] as String?,
  isBookmarked: json['isBookmarked'] as bool?,
  isLiked: json['isLiked'] as bool?,
  likes: (json['likes'] as num?)?.toInt(),
  comments_count: (json['comments_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$SongsToJson(_Songs instance) => <String, dynamic>{
  'id': instance.id,
  'account_id': instance.account_id,
  'title': instance.title,
  'artist': instance.artist,
  'created_at': instance.created_at?.toIso8601String(),
  'image_url': instance.image_url,
  'image_id': instance.image_id,
  'audio_url': instance.audio_url,
  'audio_id': instance.audio_id,
  'genre': instance.genre,
  'description': instance.description,
  'user_id': instance.user_id,
  'isBookmarked': instance.isBookmarked,
  'isLiked': instance.isLiked,
  'likes': instance.likes,
  'comments_count': instance.comments_count,
};

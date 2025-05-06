import 'package:freezed_annotation/freezed_annotation.dart';

part 'songs.g.dart';
part 'songs.freezed.dart';

@freezed
abstract class Songs with _$Songs {
  const factory Songs({
    required String? id,
    required String? account_id, // ID of the user who created the song
    required String? title, // stores the title of the song
    required String? artist, // stores the artist name
    required DateTime? created_at,
    required String? image_url, // stores the image url
    required String? image_id, // stores the image id
    required String? audio_url, // stores the audio url
    required String? audio_id, // stores the audio id
    required String? genre, // stores the genre
    String? description, // optional description of the song
    String? user_id, // ID of the user who created the song
    required bool? isBookmarked, // whether the song is bookmarked
    required bool? isLiked, // whether the song is liked
    required int? likes, // number of likes
    required int? comments_count, // number of comments
  }) = _Songs;

  factory Songs.fromJson(Map<String, dynamic> json) => _$SongsFromJson(json);
}

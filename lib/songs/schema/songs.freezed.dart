// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'songs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Songs {

 String? get id; String? get account_id;// ID of the user who created the song
 String? get title;// stores the title of the song
 String? get artist;// stores the artist name
 DateTime? get created_at; String? get image_url;// stores the image url
 String? get image_id;// stores the image id
 String? get audio_url;// stores the audio url
 String? get audio_id;// stores the audio id
 String? get genre;// stores the genre
 String? get description;// optional description of the song
 String? get user_id;// ID of the user who created the song
 bool? get isBookmarked;// whether the song is bookmarked
 bool? get isLiked;// whether the song is liked
 int? get likes;// number of likes
 int? get comments_count;
/// Create a copy of Songs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongsCopyWith<Songs> get copyWith => _$SongsCopyWithImpl<Songs>(this as Songs, _$identity);

  /// Serializes this Songs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Songs&&(identical(other.id, id) || other.id == id)&&(identical(other.account_id, account_id) || other.account_id == account_id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.image_url, image_url) || other.image_url == image_url)&&(identical(other.image_id, image_id) || other.image_id == image_id)&&(identical(other.audio_url, audio_url) || other.audio_url == audio_url)&&(identical(other.audio_id, audio_id) || other.audio_id == audio_id)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.description, description) || other.description == description)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.comments_count, comments_count) || other.comments_count == comments_count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,account_id,title,artist,created_at,image_url,image_id,audio_url,audio_id,genre,description,user_id,isBookmarked,isLiked,likes,comments_count);

@override
String toString() {
  return 'Songs(id: $id, account_id: $account_id, title: $title, artist: $artist, created_at: $created_at, image_url: $image_url, image_id: $image_id, audio_url: $audio_url, audio_id: $audio_id, genre: $genre, description: $description, user_id: $user_id, isBookmarked: $isBookmarked, isLiked: $isLiked, likes: $likes, comments_count: $comments_count)';
}


}

/// @nodoc
abstract mixin class $SongsCopyWith<$Res>  {
  factory $SongsCopyWith(Songs value, $Res Function(Songs) _then) = _$SongsCopyWithImpl;
@useResult
$Res call({
 String? id, String? account_id, String? title, String? artist, DateTime? created_at, String? image_url, String? image_id, String? audio_url, String? audio_id, String? genre, String? description, String? user_id, bool? isBookmarked, bool? isLiked, int? likes, int? comments_count
});




}
/// @nodoc
class _$SongsCopyWithImpl<$Res>
    implements $SongsCopyWith<$Res> {
  _$SongsCopyWithImpl(this._self, this._then);

  final Songs _self;
  final $Res Function(Songs) _then;

/// Create a copy of Songs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? account_id = freezed,Object? title = freezed,Object? artist = freezed,Object? created_at = freezed,Object? image_url = freezed,Object? image_id = freezed,Object? audio_url = freezed,Object? audio_id = freezed,Object? genre = freezed,Object? description = freezed,Object? user_id = freezed,Object? isBookmarked = freezed,Object? isLiked = freezed,Object? likes = freezed,Object? comments_count = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,account_id: freezed == account_id ? _self.account_id : account_id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,image_url: freezed == image_url ? _self.image_url : image_url // ignore: cast_nullable_to_non_nullable
as String?,image_id: freezed == image_id ? _self.image_id : image_id // ignore: cast_nullable_to_non_nullable
as String?,audio_url: freezed == audio_url ? _self.audio_url : audio_url // ignore: cast_nullable_to_non_nullable
as String?,audio_id: freezed == audio_id ? _self.audio_id : audio_id // ignore: cast_nullable_to_non_nullable
as String?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as String?,isBookmarked: freezed == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool?,isLiked: freezed == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool?,likes: freezed == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int?,comments_count: freezed == comments_count ? _self.comments_count : comments_count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Songs implements Songs {
  const _Songs({required this.id, required this.account_id, required this.title, required this.artist, required this.created_at, required this.image_url, required this.image_id, required this.audio_url, required this.audio_id, required this.genre, this.description, this.user_id, required this.isBookmarked, required this.isLiked, required this.likes, required this.comments_count});
  factory _Songs.fromJson(Map<String, dynamic> json) => _$SongsFromJson(json);

@override final  String? id;
@override final  String? account_id;
// ID of the user who created the song
@override final  String? title;
// stores the title of the song
@override final  String? artist;
// stores the artist name
@override final  DateTime? created_at;
@override final  String? image_url;
// stores the image url
@override final  String? image_id;
// stores the image id
@override final  String? audio_url;
// stores the audio url
@override final  String? audio_id;
// stores the audio id
@override final  String? genre;
// stores the genre
@override final  String? description;
// optional description of the song
@override final  String? user_id;
// ID of the user who created the song
@override final  bool? isBookmarked;
// whether the song is bookmarked
@override final  bool? isLiked;
// whether the song is liked
@override final  int? likes;
// number of likes
@override final  int? comments_count;

/// Create a copy of Songs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongsCopyWith<_Songs> get copyWith => __$SongsCopyWithImpl<_Songs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Songs&&(identical(other.id, id) || other.id == id)&&(identical(other.account_id, account_id) || other.account_id == account_id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.created_at, created_at) || other.created_at == created_at)&&(identical(other.image_url, image_url) || other.image_url == image_url)&&(identical(other.image_id, image_id) || other.image_id == image_id)&&(identical(other.audio_url, audio_url) || other.audio_url == audio_url)&&(identical(other.audio_id, audio_id) || other.audio_id == audio_id)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.description, description) || other.description == description)&&(identical(other.user_id, user_id) || other.user_id == user_id)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.comments_count, comments_count) || other.comments_count == comments_count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,account_id,title,artist,created_at,image_url,image_id,audio_url,audio_id,genre,description,user_id,isBookmarked,isLiked,likes,comments_count);

@override
String toString() {
  return 'Songs(id: $id, account_id: $account_id, title: $title, artist: $artist, created_at: $created_at, image_url: $image_url, image_id: $image_id, audio_url: $audio_url, audio_id: $audio_id, genre: $genre, description: $description, user_id: $user_id, isBookmarked: $isBookmarked, isLiked: $isLiked, likes: $likes, comments_count: $comments_count)';
}


}

/// @nodoc
abstract mixin class _$SongsCopyWith<$Res> implements $SongsCopyWith<$Res> {
  factory _$SongsCopyWith(_Songs value, $Res Function(_Songs) _then) = __$SongsCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? account_id, String? title, String? artist, DateTime? created_at, String? image_url, String? image_id, String? audio_url, String? audio_id, String? genre, String? description, String? user_id, bool? isBookmarked, bool? isLiked, int? likes, int? comments_count
});




}
/// @nodoc
class __$SongsCopyWithImpl<$Res>
    implements _$SongsCopyWith<$Res> {
  __$SongsCopyWithImpl(this._self, this._then);

  final _Songs _self;
  final $Res Function(_Songs) _then;

/// Create a copy of Songs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? account_id = freezed,Object? title = freezed,Object? artist = freezed,Object? created_at = freezed,Object? image_url = freezed,Object? image_id = freezed,Object? audio_url = freezed,Object? audio_id = freezed,Object? genre = freezed,Object? description = freezed,Object? user_id = freezed,Object? isBookmarked = freezed,Object? isLiked = freezed,Object? likes = freezed,Object? comments_count = freezed,}) {
  return _then(_Songs(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,account_id: freezed == account_id ? _self.account_id : account_id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,created_at: freezed == created_at ? _self.created_at : created_at // ignore: cast_nullable_to_non_nullable
as DateTime?,image_url: freezed == image_url ? _self.image_url : image_url // ignore: cast_nullable_to_non_nullable
as String?,image_id: freezed == image_id ? _self.image_id : image_id // ignore: cast_nullable_to_non_nullable
as String?,audio_url: freezed == audio_url ? _self.audio_url : audio_url // ignore: cast_nullable_to_non_nullable
as String?,audio_id: freezed == audio_id ? _self.audio_id : audio_id // ignore: cast_nullable_to_non_nullable
as String?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,user_id: freezed == user_id ? _self.user_id : user_id // ignore: cast_nullable_to_non_nullable
as String?,isBookmarked: freezed == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool?,isLiked: freezed == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool?,likes: freezed == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int?,comments_count: freezed == comments_count ? _self.comments_count : comments_count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

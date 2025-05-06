import 'package:melody_meets/auth/schemas/account.dart';
import 'package:melody_meets/songs/schema/songs.dart';

class ProfileState {
  final Account? user;
  final List<Songs> songs;
  final List<Songs> savedSongs;
  final bool isLoading;
  final bool isFollowing;
  final int followerCount;
  final int followingCount;
  final String? error;
  final bool? isLiked;
  final bool? isBookmarked;
  final int? likes;

  ProfileState({
    this.user,
    required this.songs,
    required this.savedSongs,
    required this.isLoading,
    required this.isFollowing,
    this.followerCount = 0,
    this.followingCount = 0,
    this.error,
    this.isLiked,
    this.isBookmarked,
    this.likes,
  });

  // Create a copy with updated values
  ProfileState copyWith({
    Account? user,
    List<Songs>? songs,
    List<Songs>? savedSongs,
    bool? isLoading,
    bool? isFollowing,
    int? followerCount,
    int? followingCount,
    String? error,
    bool? isLiked,
    bool? isBookmarked,
    int? likes,
  }) {
    return ProfileState(
      user: user ?? this.user,
      songs: songs ?? this.songs,
      savedSongs: savedSongs ?? this.savedSongs,
      isLoading: isLoading ?? this.isLoading,
      isFollowing: isFollowing ?? this.isFollowing,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      error: error ?? this.error,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      likes: likes ?? this.likes,
    );
  }
}

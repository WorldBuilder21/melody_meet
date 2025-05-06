import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:melody_meets/songs/api/song_repository.dart';

part 'song_state_provider.g.dart';

@riverpod
class SongState extends _$SongState {
  @override
  Songs? build(String songId) {
    return null; // Initially null, will be updated when song data is loaded
  }

  void updateSong(Songs song) {
    state = song;
  }

  Future<void> toggleLike() async {
    if (state == null) return;

    // Optimistically update UI
    final currentLiked = state!.isLiked ?? false;
    final currentLikes = state!.likes ?? 0;

    state = state!.copyWith(
      isLiked: !currentLiked,
      likes: currentLikes + (currentLiked ? -1 : 1),
    );

    try {
      // Update in database
      final songRepo = ref.read(songRepositoryProvider);
      await songRepo.toggleLike(state!.id!);

      // Refresh song data to ensure consistency
      final updatedSong = await songRepo.getSongById(state!.id!);
      if (updatedSong != null) {
        state = updatedSong;
      }
    } catch (e) {
      // Revert on error
      state = state!.copyWith(isLiked: currentLiked, likes: currentLikes);
    }
  }

  Future<void> toggleBookmark() async {
    if (state == null) return;

    // Optimistically update UI
    final currentBookmarked = state!.isBookmarked ?? false;

    state = state!.copyWith(isBookmarked: !currentBookmarked);

    try {
      // Update in database
      final songRepo = ref.read(songRepositoryProvider);
      await songRepo.toggleBookmark(state!.id!);

      // Refresh song data to ensure consistency
      final updatedSong = await songRepo.getSongById(state!.id!);
      if (updatedSong != null) {
        state = updatedSong;
      }
    } catch (e) {
      // Revert on error
      state = state!.copyWith(isBookmarked: currentBookmarked);
    }
  }
}

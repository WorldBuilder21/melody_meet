import 'package:melody_meets/auth/schemas/account.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:melody_meets/songs/api/song_repository.dart';
import 'package:melody_meets/profile/model/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

part 'profile_provider.g.dart';

// Profile provider that uses Riverpod's StateNotifier
@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isDisposed = false;

  FutureOr<ProfileState> build(String userId) {
    // Cache isCurrentUser to avoid disposal issues
    final currentUserId = _supabase.auth.currentUser?.id;
    _isCurrentUser = currentUserId == userId;
    _isDisposed = false;

    return _loadProfile(userId);
  }

  // Cache this value to avoid accessing Supabase during disposal
  bool _isCurrentUser = false;

  // Load profile data
  Future<ProfileState> _loadProfile(String userId) async {
    try {
      debugPrint('Loading profile for user: $userId');

      // Use the cached value to determine if this is the current user
      final currentUserId = _supabase.auth.currentUser?.id;

      // Fetch user data from Supabase
      final userResponse =
          await _supabase
              .from('accounts')
              .select('*')
              .eq('id', userId)
              .single();

      final user = Account.fromJson(userResponse);

      // Check if the current user is following this profile
      bool isFollowing = false;
      if (currentUserId != null && userId != currentUserId) {
        final followResponse =
            await _supabase.from('follows').select().match({
              'follower_id': currentUserId,
              'following_id': userId,
            }).maybeSingle();

        isFollowing = followResponse != null;
      }

      // Get follower count
      final followerCountResponse = await _supabase
          .from('follows')
          .select('*')
          .eq('following_id', userId);

      final followerCount = followerCountResponse.length ?? 0;

      // Get following count
      final followingCountResponse = await _supabase
          .from('follows')
          .select('*')
          .eq('follower_id', userId);

      final followingCount = followingCountResponse.length ?? 0;

      // Get song repository and load songs
      final songRepo = ref.read(songRepositoryProvider);

      // Force a cache clear to ensure fresh data
      songRepo.clearCaches();

      final songs = await songRepo.getUserSongs(userId);

      // Only load saved songs for current user
      List<Songs> savedSongs = [];
      if (currentUserId == userId) {
        savedSongs = await songRepo.getSavedSongs();
        debugPrint('Loaded ${savedSongs.length} saved songs for current user');
      }

      ref.keepAlive();

      return ProfileState(
        user: user,
        songs: songs,
        savedSongs: savedSongs,
        isLoading: false,
        isFollowing: isFollowing,
        followerCount: followerCount,
        followingCount: followingCount,
        error: null,
        isLiked: false,
        isBookmarked: false,
        likes: 0,
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return ProfileState(
        songs: [],
        savedSongs: [],
        isLoading: false,
        isFollowing: false,
        followerCount: 0,
        followingCount: 0,
        error: e.toString(),
        isLiked: false,
        isBookmarked: false,
        likes: 0,
      );
    }
  }

  // Refresh only saved songs
  Future<void> refreshSavedSongs() async {
    if (state.value == null || _isDisposed) return;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || !_isCurrentUser) return;

    try {
      debugPrint('Refreshing saved songs specifically');
      final songRepo = ref.read(songRepositoryProvider);
      final savedSongs = await songRepo.getSavedSongs();

      // Update only the saved songs in the state
      if (_isDisposed) return;

      state = AsyncValue.data(state.value!.copyWith(savedSongs: savedSongs));

      debugPrint(
        'Successfully refreshed saved songs: ${savedSongs.length} songs',
      );
    } catch (e) {
      debugPrint('Error refreshing saved songs: $e');
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    debugPrint('Refreshing profile for user: $userId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProfile(userId));
  }

  // Force refresh follow status independently
  Future<void> refreshFollowStatus() async {
    if (state.value == null || _isDisposed) return;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // Check follow status directly from database
      final followResponse =
          await _supabase.from('follows').select().match({
            'follower_id': currentUserId,
            'following_id': userId,
          }).maybeSingle();

      final isFollowing = followResponse != null;

      // Update follower count
      final followerCountResponse = await _supabase
          .from('follows')
          .select('*')
          .eq('following_id', userId);

      final followerCount = followerCountResponse.length;

      // Only update if we have a value and follow status changed
      if (state.value != null &&
          (state.value!.isFollowing != isFollowing ||
              state.value!.followerCount != followerCount)) {
        state = AsyncValue.data(
          state.value!.copyWith(
            isFollowing: isFollowing,
            followerCount: followerCount,
          ),
        );

        debugPrint(
          'Follow status updated: isFollowing=$isFollowing, followerCount=$followerCount',
        );
      }
    } catch (e) {
      debugPrint('Error refreshing follow status: $e');
    }
  }

  // Check if profile belongs to current user - now uses cached value
  bool isCurrentUserProfile() {
    return _isCurrentUser;
  }

  // Toggle follow status with improved handling
  Future<void> toggleFollow() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || state.value == null || _isDisposed) return;

    // Get current state values
    final isCurrentlyFollowing = state.value!.isFollowing;
    final currentFollowerCount = state.value!.followerCount;

    // Optimistically update UI
    state = AsyncValue.data(
      state.value!.copyWith(
        isFollowing: !isCurrentlyFollowing,
        followerCount:
            isCurrentlyFollowing
                ? currentFollowerCount - 1
                : currentFollowerCount + 1,
      ),
    );

    try {
      if (!isCurrentlyFollowing) {
        // Follow user
        await _supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('User $currentUserId followed user $userId');
      } else {
        // Unfollow user
        await _supabase.from('follows').delete().match({
          'follower_id': currentUserId,
          'following_id': userId,
        });
        debugPrint('User $currentUserId unfollowed user $userId');
      }

      // Wait a moment for database to update
      await Future.delayed(const Duration(milliseconds: 300));

      // Force refresh follow status from database to ensure consistency
      await refreshFollowStatus();
    } catch (e) {
      debugPrint('Error toggling follow status: $e');
      // Revert on error
      state = AsyncValue.data(
        state.value!.copyWith(
          isFollowing: isCurrentlyFollowing,
          followerCount: currentFollowerCount,
          error: 'Failed to update follow status: $e',
        ),
      );
    }
  }

  // Add a song to the profile's songs list with improved refresh
  Future<void> addSong(Songs song) async {
    if (state.value == null || _isDisposed) return;

    debugPrint('Adding song to profile: ${song.id}');

    // Update local state immediately for a responsive UI
    state = AsyncValue.data(
      state.value!.copyWith(songs: [song, ...state.value!.songs]),
    );

    // Force a refresh to ensure the song is properly displayed
    try {
      // Clear caches in song repository to ensure fresh data
      ref.read(songRepositoryProvider).clearCaches();

      // Small delay to ensure the database has time to update
      await Future.delayed(const Duration(milliseconds: 300));
      await refreshProfile();
      debugPrint('Profile refreshed after adding song');
    } catch (e) {
      debugPrint('Error refreshing after adding song: $e');
    }
  }

  // Update a song in the profile's songs list
  Future<void> updateSong(Songs updatedSong) async {
    if (state.value == null || _isDisposed) return;

    debugPrint('Updating song in profile: ${updatedSong.id}');

    final updatedSongs = [...state.value!.songs];
    final index = updatedSongs.indexWhere((song) => song.id == updatedSong.id);

    if (index != -1) {
      updatedSongs[index] = updatedSong;
      state = AsyncValue.data(state.value!.copyWith(songs: updatedSongs));

      // Force a refresh to ensure the song is properly updated
      try {
        // Clear caches in song repository to ensure fresh data
        ref.read(songRepositoryProvider).clearCaches();

        // Small delay to ensure the database has time to update
        await Future.delayed(const Duration(milliseconds: 300));
        await refreshProfile();
        debugPrint('Profile refreshed after updating song');
      } catch (e) {
        debugPrint('Error refreshing after updating song: $e');
      }
    }
  }

  // Remove a song from the profile's songs list
  void removeSong(String songId) {
    if (state.value == null || _isDisposed) return;

    debugPrint('Removing song from profile: $songId');

    final updatedSongs =
        state.value!.songs.where((song) => song.id != songId).toList();
    state = AsyncValue.data(state.value!.copyWith(songs: updatedSongs));
  }

  // Toggle like status for a song
  Future<void> toggleLike(String songId) async {
    if (state.value == null || _isDisposed) return;

    try {
      // Find the song in both lists
      final updatedSongs = [...state.value!.songs];
      final updatedSavedSongs = [...state.value!.savedSongs];

      // Find indices
      final songIndex = updatedSongs.indexWhere((song) => song.id == songId);
      final savedSongIndex = updatedSavedSongs.indexWhere(
        (song) => song.id == songId,
      );

      // Update in songs list
      if (songIndex != -1) {
        final song = updatedSongs[songIndex];
        final isCurrentlyLiked = song.isLiked ?? false;

        // Optimistically update UI
        updatedSongs[songIndex] = song.copyWith(
          isLiked: !isCurrentlyLiked,
          likes: (song.likes ?? 0) + (isCurrentlyLiked ? -1 : 1),
        );
      }

      // Also update in saved songs list if present
      if (savedSongIndex != -1) {
        final savedSong = updatedSavedSongs[savedSongIndex];
        final isCurrentlyLiked = savedSong.isLiked ?? false;

        updatedSavedSongs[savedSongIndex] = savedSong.copyWith(
          isLiked: !isCurrentlyLiked,
          likes: (savedSong.likes ?? 0) + (isCurrentlyLiked ? -1 : 1),
        );
      }

      // Update state optimistically
      state = AsyncValue.data(
        state.value!.copyWith(
          songs: updatedSongs,
          savedSongs: updatedSavedSongs,
        ),
      );

      // Update in database
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final song =
            songIndex != -1
                ? updatedSongs[songIndex]
                : savedSongIndex != -1
                ? updatedSavedSongs[savedSongIndex]
                : null;

        if (song != null) {
          final isLiked = song.isLiked ?? false;

          if (isLiked) {
            // Add like
            await _supabase.from('song_likes').insert({
              'user_id': currentUserId,
              'song_id': songId,
            });
          } else {
            // Remove like
            await _supabase.from('song_likes').delete().match({
              'user_id': currentUserId,
              'song_id': songId,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');

      // Revert to previous state on error
      if (!_isDisposed) {
        // Get the correct song data
        try {
          final songRepo = ref.read(songRepositoryProvider);
          final song = await songRepo.getSongById(songId);

          if (song != null) {
            final updatedSongs = [...state.value!.songs];
            final updatedSavedSongs = [...state.value!.savedSongs];

            final songIndex = updatedSongs.indexWhere((s) => s.id == songId);
            final savedSongIndex = updatedSavedSongs.indexWhere(
              (s) => s.id == songId,
            );

            if (songIndex != -1) {
              updatedSongs[songIndex] = song;
            }
            if (savedSongIndex != -1) {
              updatedSavedSongs[savedSongIndex] = song;
            }

            state = AsyncValue.data(
              state.value!.copyWith(
                songs: updatedSongs,
                savedSongs: updatedSavedSongs,
              ),
            );
          }
        } catch (innerError) {
          debugPrint('Error reverting like state: $innerError');
        }
      }
    }
  }

  // Toggle bookmark on a song with improved handling for saved songs tab
  Future<void> toggleBookmark(String songId) async {
    if (state.value == null || _isDisposed) return;

    final songRepo = ref.read(songRepositoryProvider);

    // Check if this is in songs list or saved songs list
    var updatedSongs = [...state.value!.songs];
    var songsIndex = updatedSongs.indexWhere((song) => song.id == songId);

    var updatedSavedSongs = [...state.value!.savedSongs];
    var savedSongsIndex = updatedSavedSongs.indexWhere(
      (song) => song.id == songId,
    );

    Songs? songToUpdate;
    bool currentlyBookmarked = false;

    if (songsIndex != -1) {
      songToUpdate = updatedSongs[songsIndex];
      currentlyBookmarked = songToUpdate.isBookmarked!;

      // Update in songs list
      updatedSongs[songsIndex] = songToUpdate.copyWith(
        isBookmarked: !currentlyBookmarked,
      );

      debugPrint(
        'Toggling bookmark for song $songId in songs list. Was bookmarked: $currentlyBookmarked',
      );
    }

    // Handle saved songs tab updates
    if (savedSongsIndex != -1) {
      songToUpdate = updatedSavedSongs[savedSongsIndex];
      currentlyBookmarked = true;

      // Remove from saved songs list if unbookmarking
      debugPrint('Removing song $songId from saved songs list (unbookmarking)');
      updatedSavedSongs.removeAt(savedSongsIndex);
    } else if (songsIndex != -1 && !currentlyBookmarked) {
      // Add to saved songs if bookmarking
      debugPrint('Adding song $songId to saved songs list (bookmarking)');
      updatedSavedSongs.add(songToUpdate!.copyWith(isBookmarked: true));
    }

    // Update UI immediately
    state = AsyncValue.data(
      state.value!.copyWith(songs: updatedSongs, savedSongs: updatedSavedSongs),
    );

    try {
      // Update in database
      await songRepo.toggleBookmark(songId);

      // Refresh saved songs from server after a short delay
      // This ensures our local state matches the server state
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isDisposed) return;
        refreshSavedSongs();
      });
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');

      // Revert UI on error
      state = AsyncValue.data(
        state.value!.copyWith(
          songs: state.value!.songs,
          savedSongs: state.value!.savedSongs,
          error: 'Failed to update bookmark status: $e',
        ),
      );
    }
  }

  // Add song to saved songs directly
  Future<void> addToSavedSongs(Songs song) async {
    if (state.value == null || !_isCurrentUser || _isDisposed) return;

    final updatedSavedSongs = [...state.value!.savedSongs];

    // Only add if not already in saved songs
    if (!updatedSavedSongs.any((s) => s.id == song.id)) {
      // Make sure the song is marked as bookmarked
      final songWithBookmark = song.copyWith(isBookmarked: true);
      updatedSavedSongs.add(songWithBookmark);

      // Update UI immediately
      state = AsyncValue.data(
        state.value!.copyWith(savedSongs: updatedSavedSongs),
      );

      debugPrint('Added song ${song.id} directly to saved songs tab');
    }
  }

  // Remove song from saved songs directly
  Future<void> removeFromSavedSongs(String songId) async {
    if (state.value == null || !_isCurrentUser || _isDisposed) return;

    final updatedSavedSongs = [...state.value!.savedSongs];
    final index = updatedSavedSongs.indexWhere((s) => s.id == songId);

    if (index != -1) {
      updatedSavedSongs.removeAt(index);

      // Update UI immediately
      state = AsyncValue.data(
        state.value!.copyWith(savedSongs: updatedSavedSongs),
      );

      debugPrint('Removed song $songId directly from saved songs tab');
    }
  }
}

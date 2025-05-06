import 'package:melody_meets/songs/api/song_repository.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider that gives access to the FeedNotifier
final feedProvider = Provider<FeedNotifier>((ref) {
  return FeedNotifier(ref);
});

// StateNotifierProvider that actually manages the feed state
final feedNotifier = StateNotifierProvider<
  FeedNotifier,
  AsyncValue<List<Songs>>
>((ref) {
  final notifier = FeedNotifier(ref);
  // Use Future.microtask to schedule the initial load after the widget tree is built
  Future.microtask(() => notifier.loadFeed());
  return notifier;
});

// Feed notifier
class FeedNotifier extends StateNotifier<AsyncValue<List<Songs>>> {
  final Ref _ref;
  int _currentPage = 0;
  bool _hasMore = true;
  final int _songsPerPage = 10;
  bool _isLoading = false;
  bool _disposed = false;

  // Add cache timestamp to know when to refresh
  DateTime? _lastLoadTime;

  FeedNotifier(this._ref) : super(const AsyncValue.loading());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadFeed() async {
    // Prevent multiple simultaneous loads and avoid loading when disposed
    if (_isLoading || _disposed) return;

    _isLoading = true;

    // Always show loading state on complete refresh to avoid UI glitches
    if (!_disposed) {
      state = const AsyncValue.loading();
    }

    // Reset pagination
    _currentPage = 0;
    _hasMore = true;

    try {
      debugPrint('Loading feed from repository...');
      final songRepo = _ref.read(songRepositoryProvider);

      // Clear repository cache first to ensure fresh data
      songRepo.clearCaches();

      // Add try-finally to ensure _isLoading is reset
      try {
        final songs = await songRepo.getFeedSongs(
          page: _currentPage,
          limit: _songsPerPage,
        );

        if (!_disposed) {
          // Keep reference alive
          _ref.keepAlive();

          debugPrint('Loaded ${songs.length} songs');
          _hasMore = songs.length == _songsPerPage;
          _currentPage++;

          // Update state
          state = AsyncValue.data(songs);

          // Update timestamp
          _lastLoadTime = DateTime.now();
        }
      } finally {
        _isLoading = false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading feed: $e');

      if (!_disposed) {
        state = AsyncValue.error(e, stackTrace);
      }

      _isLoading = false;
    }
  }

  Future<void> loadMoreSongs() async {
    // Skip if we don't have more songs, are already loading, are in error state, or are disposed
    if (!_hasMore || _isLoading || state is AsyncError || _disposed) return;

    _isLoading = true;

    try {
      // Get current songs - only proceed if we have some
      final currentSongs = state.value ?? [];
      if (currentSongs.isEmpty) {
        _isLoading = false;
        return;
      }

      final songRepo = _ref.read(songRepositoryProvider);

      debugPrint('Loading more songs from page $_currentPage');
      final newSongs = await songRepo.getFeedSongs(
        page: _currentPage,
        limit: _songsPerPage,
      );

      if (!_disposed) {
        debugPrint('Loaded ${newSongs.length} more songs');
        _hasMore = newSongs.length == _songsPerPage;
        _currentPage++;

        _ref.keepAlive();

        // Append new songs to existing songs
        state = AsyncValue.data([...currentSongs, ...newSongs]);
      }
    } catch (e, stackTrace) {
      // Keep existing songs on error
      if (!_disposed) {
        if (state.hasValue) {
          // Just log the error for pagination but don't update state
          debugPrint('Error loading more songs: $e');
        } else {
          state = AsyncValue.error(e, stackTrace);
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  // Check if feed needs a refresh based on time
  bool get needsRefresh {
    // Always refresh if never loaded or if it's been more than 1 minute
    return _lastLoadTime == null ||
        DateTime.now().difference(_lastLoadTime!) > const Duration(minutes: 1);
  }

  // Refresh feed, potentially keeping current songs if refresh fails
  Future<void> refreshFeed() async {
    if (_isLoading || _disposed) return;

    // Save current songs before refreshing for fallback
    final currentSongs = state.hasValue ? state.value! : <Songs>[];

    _isLoading = true;

    // Don't change state to loading to avoid flicker
    // This way, current songs remain visible during refresh

    // Reset pagination
    _currentPage = 0;
    _hasMore = true;

    try {
      debugPrint('Refreshing feed...');
      final songRepo = _ref.read(songRepositoryProvider);

      // Clear caches first to ensure fresh data
      songRepo.clearCaches();

      final songs = await songRepo.getFeedSongs(
        page: _currentPage,
        limit: _songsPerPage,
      );

      if (!_disposed) {
        // Keep reference alive
        _ref.keepAlive();

        debugPrint('Loaded ${songs.length} songs on refresh');
        _hasMore = songs.length == _songsPerPage;
        _currentPage++;

        // Update state with new songs
        state = AsyncValue.data(songs);

        // Update timestamp
        _lastLoadTime = DateTime.now();
      }
    } catch (e, stackTrace) {
      debugPrint('Error refreshing feed: $e');

      if (!_disposed) {
        // If we had songs before, keep them instead of showing error
        if (currentSongs.isNotEmpty) {
          // Keep current songs but still mark as needing refresh
          _lastLoadTime = null;
          debugPrint('Keeping current songs after refresh failure');
        } else {
          // Only show error if we had no songs before
          state = AsyncValue.error(e, stackTrace);
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  void toggleLike(String songId) {
    if (!state.hasValue || _disposed) return;

    final songs = [...state.value!];
    final index = songs.indexWhere((song) => song.id == songId);
    if (index == -1) return;

    final song = songs[index];
    final isLiked = song.isLiked ?? false;

    // Optimistically update UI
    songs[index] = song.copyWith(
      isLiked: !isLiked,
      likes: (song.likes ?? 0) + (isLiked ? -1 : 1),
    );

    if (!_disposed) {
      state = AsyncValue.data(songs);

      // Update in database
      _ref.read(songRepositoryProvider).toggleLike(songId).catchError((e) {
        // Revert on error
        if (!_disposed) {
          songs[index] = song;
          state = AsyncValue.data(songs);
          debugPrint('Error toggling like: $e');
        }
      });
    }
  }

  void toggleBookmark(String songId) {
    if (!state.hasValue || _disposed) return;

    final songs = [...state.value!];
    final index = songs.indexWhere((song) => song.id == songId);
    if (index == -1) return;

    final song = songs[index];
    final isBookmarked = song.isBookmarked ?? false;

    // Optimistically update UI
    songs[index] = song.copyWith(isBookmarked: !isBookmarked);

    if (!_disposed) {
      state = AsyncValue.data(songs);

      // Update in database
      _ref.read(songRepositoryProvider).toggleBookmark(songId).catchError((e) {
        // Revert on error
        if (!_disposed) {
          songs[index] = song;
          state = AsyncValue.data(songs);
          debugPrint('Error toggling bookmark: $e');
        }
      });
    }
  }

  // Add a new song to the feed (used after creating a song)
  void addSong(Songs song) {
    if (!state.hasValue || _disposed) return;

    // Add to the beginning of the feed
    final currentSongs = state.value!;
    final updatedSongs = [song, ...currentSongs];

    if (!_disposed) {
      state = AsyncValue.data(updatedSongs);

      // Force a cache refresh immediately
      _lastLoadTime = null;
      debugPrint('Song added to feed and cache time reset');
    }
  }

  // Force a full refresh of feed on next check
  void invalidateCache() {
    _lastLoadTime = null;
    _ref.read(songRepositoryProvider).clearCaches();
    debugPrint('Feed cache explicitly invalidated');
  }
}

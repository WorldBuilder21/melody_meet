import 'dart:io';
import 'package:melody_meets/auth/schemas/account.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

part 'song_repository.g.dart';

@Riverpod(keepAlive: true)
SongRepository songRepository(SongRepositoryRef _) => SongRepository();

class SongRepository {
  final _supabase = Supabase.instance.client;

  // Cache control
  bool _needsFreshData = true; // Start with fresh data by default
  Map<String, List<Songs>> _songCache = {};
  Map<String, Songs> _singleSongCache = {};
  Map<String, DateTime> _lastCacheTime = {};
  DateTime _lastGlobalRefresh = DateTime.now().subtract(
    const Duration(minutes: 10),
  ); // Force initial refresh

  // Clear all caches
  void clearCaches() {
    _songCache.clear();
    _singleSongCache.clear();
    _lastCacheTime.clear();
    _needsFreshData = true;
    _lastGlobalRefresh = DateTime.now();
    debugPrint('SongRepository: All caches cleared');
  }

  // Get a user's songs
  Future<List<Songs>> getUserSongs(String userId) async {
    // Always check if we need fresh data first
    final isTimeToRefresh =
        DateTime.now().difference(_lastGlobalRefresh) >
        const Duration(minutes: 2);

    if (isTimeToRefresh) {
      _needsFreshData = true;
      _lastGlobalRefresh = DateTime.now();
      debugPrint('SongRepository: Global cache expired, refreshing user songs');
    }

    final cacheKey = 'user_$userId';

    // Return cached songs if available and recent (not older than 30 seconds)
    // and if we don't need fresh data
    if (!_needsFreshData &&
        _songCache.containsKey(cacheKey) &&
        _lastCacheTime.containsKey(cacheKey) &&
        DateTime.now().difference(_lastCacheTime[cacheKey]!) <
            const Duration(seconds: 30)) {
      debugPrint(
        'Returning cached songs for user $userId (cache age: ${DateTime.now().difference(_lastCacheTime[cacheKey]!).inSeconds}s)',
      );
      return _songCache[cacheKey]!;
    }

    try {
      debugPrint('Fetching fresh songs for user $userId');
      final currentUserId = _supabase.auth.currentUser?.id;

      // Get songs without likes check first
      final response = await _supabase
          .from('songs')
          .select('''
          *,
          accounts:account_id(
            id, 
            username, 
            email, 
            image_url, 
            bio, 
            created_at
          )
        ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('Found ${response.length} songs for user $userId');

      // Process and enrich songs with like and bookmark status
      final songs = await _processAndEnrichSongs(response);

      // Update cache
      _songCache[cacheKey] = songs;
      _lastCacheTime[cacheKey] = DateTime.now();
      _needsFreshData = false;

      return songs;
    } catch (e) {
      debugPrint('Error getting user songs: $e');

      // Return cached data if available
      if (_songCache.containsKey(cacheKey)) {
        debugPrint('Returning cached songs for user $userId after error');
        return _songCache[cacheKey]!;
      }

      throw Exception('Failed to get user songs: $e');
    }
  }

  // Get saved songs for current user
  Future<List<Songs>> getSavedSongs() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final cacheKey = 'saved_$currentUserId';

    // Check if we need fresh data
    final isTimeToRefresh =
        DateTime.now().difference(_lastGlobalRefresh) >
        const Duration(minutes: 2);

    if (isTimeToRefresh) {
      _needsFreshData = true;
      _lastGlobalRefresh = DateTime.now();
      debugPrint(
        'SongRepository: Global cache expired, refreshing saved songs',
      );
    }

    // Return cached songs if available and fresh
    if (!_needsFreshData &&
        _songCache.containsKey(cacheKey) &&
        _lastCacheTime.containsKey(cacheKey) &&
        DateTime.now().difference(_lastCacheTime[cacheKey]!) <
            const Duration(seconds: 30)) {
      debugPrint(
        'Returning cached saved songs (cache age: ${DateTime.now().difference(_lastCacheTime[cacheKey]!).inSeconds}s)',
      );
      return _songCache[cacheKey]!;
    }

    try {
      debugPrint('Fetching saved songs for user $currentUserId');

      // Get saved songs through bookmarks
      final response = await _supabase
          .from('bookmarks')
          .select('''
          songs:song_id(
            *,
            accounts:account_id(
              id, 
              username, 
              email, 
              image_url, 
              bio, 
              created_at
            )
          )
        ''')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        debugPrint('No saved songs found');
        // Update cache with empty list
        _songCache[cacheKey] = [];
        _lastCacheTime[cacheKey] = DateTime.now();
        _needsFreshData = false;
        return [];
      }

      // Process each bookmark to get the song data
      List<Songs> songs = [];
      for (final bookmarkData in response) {
        if (bookmarkData['songs'] == null) continue;

        final songData = bookmarkData['songs'];
        try {
          // Create a song with isBookmarked=true since this is from bookmarks
          final song = await _enrichSongWithUserStatus(
            Songs.fromJson(songData),
            isBookmarked: true,
          );
          songs.add(song);
        } catch (e) {
          debugPrint('Error parsing saved song: $e');
          // Continue to next song
        }
      }

      // Update cache
      _songCache[cacheKey] = songs;
      _lastCacheTime[cacheKey] = DateTime.now();
      _needsFreshData = false;

      debugPrint('Successfully fetched ${songs.length} saved songs');
      return songs;
    } catch (e) {
      debugPrint('Error getting saved songs: $e');

      // Return cached data if available
      if (_songCache.containsKey(cacheKey)) {
        debugPrint('Returning cached saved songs after error');
        return _songCache[cacheKey]!;
      }

      throw Exception('Failed to get saved songs: $e');
    }
  }

  // Get feed songs (from users being followed)
  Future<List<Songs>> getFeedSongs({int page = 0, int limit = 10}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final cacheKey = 'feed_${page}_$limit';

      // Check if we need fresh data
      final isTimeToRefresh =
          DateTime.now().difference(_lastGlobalRefresh) >
          const Duration(minutes: 2);

      if (isTimeToRefresh) {
        _needsFreshData = true;
        _lastGlobalRefresh = DateTime.now();
        debugPrint('SongRepository: Feed cache expired, refreshing data');
      }

      // Return cached data if available and fresh
      if (!_needsFreshData &&
          _songCache.containsKey(cacheKey) &&
          _lastCacheTime.containsKey(cacheKey) &&
          DateTime.now().difference(_lastCacheTime[cacheKey]!) <
              const Duration(seconds: 30)) {
        debugPrint('Returning cached feed songs');
        return _songCache[cacheKey]!;
      }

      // First get the users that the current user follows
      final followingResponse = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      // Extract the following IDs
      final followingIds =
          followingResponse
              .map((follow) => follow['following_id'] as String)
              .toList();

      // If not following anyone, return empty list
      if (followingIds.isEmpty) {
        _songCache[cacheKey] = [];
        _lastCacheTime[cacheKey] = DateTime.now();
        _needsFreshData = false;
        return [];
      }

      // Then get the songs from those users
      final response = await _supabase
          .from('songs')
          .select('''
          *,
          accounts:user_id (
            id, 
            username, 
            email, 
            image_url, 
            bio, 
            created_at
          )
          ''')
          .inFilter('user_id', followingIds)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      debugPrint('Found ${response.length} feed songs');

      // Process and enrich songs with like and bookmark status
      final songs = await _processAndEnrichSongs(response);

      // Update cache
      _songCache[cacheKey] = songs;
      _lastCacheTime[cacheKey] = DateTime.now();
      _needsFreshData = false;

      return songs;
    } catch (e) {
      debugPrint('Error getting feed songs: $e');

      throw Exception('Failed to get feed songs: $e');
    }
  }

  // Process song data and add like/bookmark status
  Future<List<Songs>> _processAndEnrichSongs(List<dynamic> response) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final List<Songs> songs = [];

    if (currentUserId == null) {
      // If no user is logged in, return songs without like/bookmark info
      for (final item in response) {
        try {
          final song = Songs.fromJson(item);
          songs.add(song);
        } catch (e) {
          debugPrint('Error processing song: $e');
        }
      }
      return songs;
    }

    // Get all song IDs from the response
    final songIds = response.map((item) => item['id'] as String).toList();

    // If no songs, return empty list
    if (songIds.isEmpty) {
      return [];
    }

    // Get all likes by this user for these songs in one query
    final likesResponse = await _supabase
        .from('likes')
        .select('song_id')
        .eq('user_id', currentUserId)
        .inFilter('song_id', songIds);

    // Get all bookmarks by this user for these songs in one query
    final bookmarksResponse = await _supabase
        .from('bookmarks')
        .select('song_id')
        .eq('user_id', currentUserId)
        .inFilter('song_id', songIds);

    // Create sets for efficient lookup
    final likedSongIds =
        likesResponse.map((like) => like['song_id'] as String).toSet();

    final bookmarkedSongIds =
        bookmarksResponse
            .map((bookmark) => bookmark['song_id'] as String)
            .toSet();

    // Process each song and add like/bookmark status
    for (final item in response) {
      try {
        final song = Songs.fromJson(item);

        // Add to single song cache
        _singleSongCache[song.id!] = song;

        // Add like and bookmark status
        final enrichedSong = song.copyWith(
          isLiked: likedSongIds.contains(song.id),
          isBookmarked: bookmarkedSongIds.contains(song.id),
        );

        songs.add(enrichedSong);
      } catch (e) {
        debugPrint('Error processing song: $e');
      }
    }

    return songs;
  }

  // Enrich a single song with user status
  Future<Songs> _enrichSongWithUserStatus(
    Songs song, {
    bool? isBookmarked,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return song;

    // If isBookmarked is already provided, use it
    bool songIsBookmarked = isBookmarked ?? false;

    // If not provided, check if the song is bookmarked
    if (isBookmarked == null) {
      final bookmarkResponse =
          await _supabase
              .from('bookmarks')
              .select()
              .eq('user_id', currentUserId)
              .eq('song_id', song.id!)
              .maybeSingle();

      songIsBookmarked = bookmarkResponse != null;
    }

    // Check if song is liked
    final likeResponse =
        await _supabase
            .from('likes')
            .select()
            .eq('user_id', currentUserId)
            .eq('song_id', song.id!)
            .maybeSingle();

    final isLiked = likeResponse != null;

    // Return enriched song
    return song.copyWith(isLiked: isLiked, isBookmarked: songIsBookmarked);
  }

  // Toggle like status for a song
  Future<void> toggleLike(String songId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already liked
      final likeResponse =
          await _supabase
              .from('likes')
              .select()
              .eq('user_id', currentUserId)
              .eq('song_id', songId)
              .maybeSingle();

      final isLiked = likeResponse != null;

      if (isLiked) {
        // Unlike
        await _supabase
            .from('likes')
            .delete()
            .eq('user_id', currentUserId)
            .eq('song_id', songId);

        debugPrint('Unliked song $songId');
      } else {
        // Like
        await _supabase.from('likes').insert({
          'user_id': currentUserId,
          'song_id': songId,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('Liked song $songId');
      }

      // Force fresh data on next load
      _needsFreshData = true;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Toggle bookmark status for a song
  Future<void> toggleBookmark(String songId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already bookmarked
      final bookmarkResponse =
          await _supabase
              .from('bookmarks')
              .select()
              .eq('user_id', currentUserId)
              .eq('song_id', songId)
              .maybeSingle();

      final isBookmarked = bookmarkResponse != null;

      if (isBookmarked) {
        // Remove bookmark
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', currentUserId)
            .eq('song_id', songId);

        debugPrint('Removed bookmark for song $songId');
      } else {
        // Add bookmark
        await _supabase.from('bookmarks').insert({
          'user_id': currentUserId,
          'song_id': songId,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('Bookmarked song $songId');
      }

      // Force fresh data on next load
      _needsFreshData = true;
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  // Delete a song
  Future<void> deleteSong(String songId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get song details first to know which files to delete
      final songDetails = _singleSongCache[songId];

      // Delete song from database
      await _supabase
          .from('songs')
          .delete()
          .eq('id', songId)
          .eq('user_id', currentUserId); // Ensure user owns the song

      // Delete song files from storage
      if (songDetails != null) {
        try {
          // Delete cover image if it exists
          if (songDetails.image_id != null) {
            await _supabase.storage.from('song_covers').remove([
              '$currentUserId/${songDetails.image_id}',
            ]);
          }

          // Delete audio file if it exists
          if (songDetails.audio_id != null) {
            await _supabase.storage.from('audio_files').remove([
              '$currentUserId/${songDetails.audio_id}',
            ]);
          }
        } catch (e) {
          // Continue even if file deletion fails
          debugPrint('Warning: Error deleting files for song $songId: $e');
        }
      }

      // Clear all caches
      clearCaches();

      debugPrint('Song deleted successfully, all caches cleared');
    } catch (e) {
      debugPrint('Error deleting song: $e');
      throw Exception('Failed to delete song: $e');
    }
  }

  // Get a single song by ID
  Future<Songs?> getSongById(String songId) async {
    try {
      final response =
          await _supabase
              .from('songs')
              .select('''
            *,
            user:user_id (
              id,
              username,
              email,
              image_url,
              created_at
            )
          ''')
              .eq('id', songId)
              .single();

      if (response == null) return null;

      // Get current user ID for like status
      final currentUserId = _supabase.auth.currentUser?.id;
      bool isLiked = false;
      bool isBookmarked = false;

      if (currentUserId != null) {
        // Check if song is liked
        final likeResponse =
            await _supabase.from('song_likes').select().match({
              'user_id': currentUserId,
              'song_id': songId,
            }).maybeSingle();
        isLiked = likeResponse != null;

        // Check if song is bookmarked
        final bookmarkResponse =
            await _supabase.from('bookmarks').select().match({
              'user_id': currentUserId,
              'song_id': songId,
            }).maybeSingle();
        isBookmarked = bookmarkResponse != null;
      }

      // Create song with like and bookmark status
      final song = Songs.fromJson(response);
      return song.copyWith(isLiked: isLiked, isBookmarked: isBookmarked);
    } catch (e) {
      debugPrint('Error getting song by ID: $e');
      return null;
    }
  }
}

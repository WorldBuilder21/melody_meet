import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/songs/model/song_comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:melody_meets/auth/schemas/account.dart';

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final String songId;
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _commentsSubscription;

  CommentsNotifier(this.songId) : super(const AsyncValue.loading()) {
    loadComments();
    _subscribeToComments();
  }

  void _subscribeToComments() {
    _commentsSubscription = _supabase
        .channel('comments:$songId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'song_comments',
          callback: (payload) async {
            if (payload.newRecord['song_id'] == songId) {
              debugPrint('Received comment update: ${payload.toString()}');
              await loadComments();
            }
          },
        )
        .subscribe((status, [_]) {
          debugPrint('Comment subscription status: $status');
        });
  }

  @override
  void dispose() {
    _commentsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();

    try {
      // Fetch comments for this song with user relationships
      final response = await _supabase
          .from('song_comments')
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
          .eq('song_id', songId)
          .order('created_at', ascending: true);

      debugPrint('Comments response: $response');
      final currentUserId = _supabase.auth.currentUser?.id;
      final List<Comment> comments = [];

      for (final commentData in response) {
        try {
          final userData = commentData['user'] as Map<String, dynamic>;
          debugPrint('User data for comment: $userData');

          final user = Account.fromJson(userData);
          final commentId = commentData['id'];

          // Handle likes count and user like status
          int likesCount = 0;
          bool isLiked = false;

          try {
            // Get likes count
            final likesResponse = await _supabase
                .from('comment_likes')
                .select('*')
                .eq('comment_id', commentId);
            likesCount = likesResponse.length;

            // Check if user liked this comment
            if (currentUserId != null) {
              final likeCheckResponse = await _supabase
                  .from('comment_likes')
                  .select()
                  .eq('comment_id', commentId)
                  .eq('user_id', currentUserId);
              isLiked = likeCheckResponse.isNotEmpty;
            }
          } catch (e) {
            debugPrint('Error getting likes: $e');
          }

          comments.add(
            Comment(
              id: commentId,
              songId: commentData['song_id'],
              user: user,
              content: commentData['content'],
              createdAt: DateTime.parse(commentData['created_at']),
              likes: likesCount,
              isLiked: isLiked,
              image_url: commentData['image_url'],
              comment_image_url: commentData['comment_image_url'],
              location: commentData['location'],
            ),
          );
        } catch (e) {
          debugPrint('Error processing comment: $e');
          debugPrint('Comment data: $commentData');
        }
      }

      state = AsyncValue.data(comments);
    } catch (e, stackTrace) {
      debugPrint('Error loading comments: $e');
      debugPrint('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addComment(
    String? content, {
    String? commentImageUrl,
    String? location,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the user data
      final userResponse =
          await _supabase
              .from('accounts')
              .select()
              .eq('id', currentUserId)
              .single();

      final user = Account.fromJson(userResponse);

      // Add comment to database
      final response =
          await _supabase
              .from('song_comments')
              .insert({
                'song_id': songId,
                'user_id': currentUserId,
                'content': content,
                'created_at': DateTime.now().toIso8601String(),
                'comment_image_url': commentImageUrl,
                'location': location,
              })
              .select()
              .single();

      // Create comment object with the user data we fetched
      final newComment = Comment(
        id: response['id'],
        songId: response['song_id'],
        user: user,
        content: response['content'],
        createdAt: DateTime.parse(response['created_at']),
        likes: 0,
        isLiked: false,
        image_url: user.image_url, // Use user's profile image
        comment_image_url: response['comment_image_url'],
        location: response['location'],
      );

      // Update state
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newComment]);
      } else {
        state = AsyncValue.data([newComment]);
      }

      // Update comments count on song
      try {
        await _supabase.rpc(
          'increment_song_comments_count',
          params: {'song_id': songId},
        );
      } catch (e) {
        debugPrint('Failed to increment comments count: $e');
        // Continue anyway as this is not critical
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding comment: $e');
      // If we already have comments, keep the current state and just report the error
      if (!state.hasValue) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow; // Let the UI handle the error display
    }
  }

  Future<void> toggleLike(String commentId) async {
    if (!state.hasValue) return;

    // Find the comment in our state
    final comments = [...state.value!];
    final index = comments.indexWhere((comment) => comment.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final isLiked = comment.isLiked;

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // First perform the database operation before updating the UI
      if (isLiked) {
        // Unlike
        await _supabase.from('comment_likes').delete().match({
          'user_id': currentUserId,
          'comment_id': commentId,
        });
      } else {
        // Like
        await _supabase.from('comment_likes').insert({
          'user_id': currentUserId,
          'comment_id': commentId,
        });
      }

      // After successful DB operation, update the UI
      comments[index] = Comment(
        id: comment.id,
        songId: comment.songId,
        user: comment.user,
        content: comment.content,
        createdAt: comment.createdAt,
        likes: isLiked ? comment.likes - 1 : comment.likes + 1,
        isLiked: !isLiked,
        image_url: comment.image_url,
        comment_image_url: comment.comment_image_url,
        location: comment.location,
      );

      state = AsyncValue.data(comments);
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // We don't need to revert the UI since we haven't updated it yet
    }
  }

  Future<void> deleteComment(String commentId) async {
    if (!state.hasValue) return;

    final comments = [...state.value!];
    final index = comments.indexWhere((comment) => comment.id == commentId);
    if (index == -1) return;

    try {
      // First delete from database
      await _supabase.from('song_comments').delete().eq('id', commentId);

      // Try to decrement comment count
      try {
        await _supabase.rpc(
          'decrement_song_comments_count',
          params: {'song_id': songId},
        );
      } catch (e) {
        debugPrint('Failed to decrement comments count: $e');
        // Continue anyway as this is not critical
      }

      // After successful DB operation, update the UI
      comments.removeAt(index);
      state = AsyncValue.data(comments);
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      // We don't need to revert the UI since we haven't updated it yet
    }
  }
}

// Provider for comments
final commentsProvider = StateNotifierProvider.family<
  CommentsNotifier,
  AsyncValue<List<Comment>>,
  String
>((ref, songId) => CommentsNotifier(songId));

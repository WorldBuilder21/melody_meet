import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/auth/schemas/account.dart';
import 'package:melody_meets/profile/provider/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

// Extended user account with follow status
class UserWithFollowStatus {
  final Account account;
  bool isFollowing;

  UserWithFollowStatus({required this.account, this.isFollowing = false});
}

// Provider to store the search results with follow status
final userSearchProvider = StateNotifierProvider<
  UserSearchNotifier,
  AsyncValue<List<UserWithFollowStatus>>
>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return UserSearchNotifier(ref, authRepo);
});

// Provider to track the search query
final searchQueryProvider = StateProvider<String>((ref) => '');

class UserSearchNotifier
    extends StateNotifier<AsyncValue<List<UserWithFollowStatus>>> {
  final AuthRepository _authRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Ref _ref;

  UserSearchNotifier(this._ref, this._authRepository)
    : super(const AsyncValue.data([]));

  // Helper to get current user ID safely
  String? _getCurrentUserId() {
    try {
      return _supabase.auth.currentUser?.id;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // Get suggested users (users with most followers or recently joined)
  Future<void> getSuggestedUsers() async {
    try {
      state = const AsyncValue.loading();

      // Get current user ID
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Build query
      var query = _supabase.from('accounts').select();

      // Exclude current user
      query = query.not('id', 'eq', currentUserId);

      // Complete the query with ordering and limit
      final response = await query
          .order('created_at', ascending: false)
          .limit(20);

      // Fetch follow status for each user
      final List<UserWithFollowStatus> usersWithStatus = [];

      // Get all follows in one query for efficiency
      final followsResponse = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', currentUserId);

      // Create a set of followed user IDs for faster lookups
      final Set<String> followedUserIds = Set<String>();

      for (final follow in followsResponse) {
        if (follow.containsKey('following_id')) {
          followedUserIds.add(follow['following_id'] as String);
        }
      }

      // Process users with follow status
      for (final user in response) {
        try {
          final account = Account.fromJson(user);
          final isFollowing = followedUserIds.contains(account.id);

          usersWithStatus.add(
            UserWithFollowStatus(account: account, isFollowing: isFollowing),
          );
        } catch (e) {
          debugPrint('Error parsing user: $e');
        }
      }

      state = AsyncValue.data(usersWithStatus);
    } catch (e, stackTrace) {
      debugPrint('Error getting suggested users: $e');
      state = const AsyncValue.data([]);
    }
  }

  // Search for users by username or email
  Future<void> searchUsers(String searchQuery) async {
    if (searchQuery.isEmpty) {
      // If query is empty, show suggested users
      await getSuggestedUsers();
      return;
    }

    try {
      state = const AsyncValue.loading();
      debugPrint('Starting search with query: $searchQuery');

      // Get current user ID
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Format search query for text search
      final formattedQuery = searchQuery
          .split(' ')
          .map((word) => "'$word'")
          .join(' | ');
      debugPrint('Formatted search query: $formattedQuery');

      // Use Supabase text search with configuration
      final response = await _supabase
          .from('accounts')
          .select('*')
          .not('id', 'eq', currentUserId)
          .or('username.ilike.%${searchQuery}%,email.ilike.%${searchQuery}%')
          .order('username', ascending: true)
          .limit(20);

      debugPrint('User response: $response');
      debugPrint('Number of users found: ${response.length}');

      // Fetch follow status for each user
      final List<UserWithFollowStatus> usersWithStatus = [];

      // Get all follows in one query for efficiency
      final followsResponse = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', currentUserId);

      debugPrint('Follows response: ${followsResponse.length} follows found');

      // Create a set of followed user IDs for faster lookups
      final Set<String> followedUserIds = Set<String>();
      for (final follow in followsResponse) {
        if (follow.containsKey('following_id')) {
          followedUserIds.add(follow['following_id'] as String);
        }
      }

      // Process users with follow status
      for (final user in response) {
        debugPrint('Processing user: $user');
        try {
          final account = Account.fromJson(user);
          final isFollowing = followedUserIds.contains(account.id);

          usersWithStatus.add(
            UserWithFollowStatus(account: account, isFollowing: isFollowing),
          );
          debugPrint('Added user to results: ${account.username}');
        } catch (e) {
          debugPrint('Error parsing user: $e');
        }
      }

      debugPrint('Final number of processed users: ${usersWithStatus.length}');
      state = AsyncValue.data(usersWithStatus);
    } catch (e, stackTrace) {
      debugPrint('Error searching users: $e');
      debugPrint('Stack trace: $stackTrace');
      state = const AsyncValue.data([]);
    }
  }

  // Toggle follow status - with profile provider synchronization
  Future<void> toggleFollow(String userId) async {
    try {
      // Get current user ID
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return;

      // Find the user in our current state
      final currentState = state.value ?? [];
      final userIndex = currentState.indexWhere((u) => u.account.id == userId);

      if (userIndex == -1) return;

      // Get the current follow status
      final isCurrentlyFollowing = currentState[userIndex].isFollowing;

      // Create a new list with the updated status for this user
      final updatedList =
          currentState.map((userWithStatus) {
            if (userWithStatus.account.id == userId) {
              return UserWithFollowStatus(
                account: userWithStatus.account,
                isFollowing: !isCurrentlyFollowing,
              );
            }
            return userWithStatus;
          }).toList();

      // Update UI immediately
      state = AsyncValue.data(updatedList);

      // Update database based on new state
      if (!isCurrentlyFollowing) {
        // Follow
        await _supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('Followed user $userId from search');
      } else {
        // Unfollow
        await _supabase.from('follows').delete().match({
          'follower_id': currentUserId,
          'following_id': userId,
        });

        debugPrint('Unfollowed user $userId from search');
      }

      // Refresh profile provider if it exists for this user
      try {
        final profileProviderExists = _ref.exists(profileProvider(userId));
        if (profileProviderExists) {
          debugPrint('Refreshing profile provider for user $userId');
          await _ref.read(profileProvider(userId).notifier).refreshProfile();
        }
      } catch (err) {
        debugPrint('Error refreshing profile after toggle follow: $err');
      }
    } catch (e) {
      debugPrint('Error toggling follow status: $e');

      // If there's an error, revert the optimistic update
      try {
        // Get the correct follow status
        final currentUserId = _getCurrentUserId();
        if (currentUserId == null) return;

        final followsResponse = await _supabase
            .from('follows')
            .select()
            .eq('follower_id', currentUserId);

        // Create set of followed user IDs
        final followedUserIds = Set<String>();
        for (final follow in followsResponse) {
          if (follow.containsKey('following_id')) {
            followedUserIds.add(follow['following_id'] as String);
          }
        }

        // Update state with correct follow status
        final currentState = state.value ?? [];
        final correctedList =
            currentState.map((userWithStatus) {
              if (userWithStatus.account.id == userId) {
                return UserWithFollowStatus(
                  account: userWithStatus.account,
                  isFollowing: followedUserIds.contains(userId),
                );
              }
              return userWithStatus;
            }).toList();

        state = AsyncValue.data(correctedList);
      } catch (innerError) {
        debugPrint('Error reverting follow state: $innerError');
      }
    }
  }

  // Clear search results
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

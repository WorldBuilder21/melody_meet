import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/home/provider/user_search_provider.dart';
import 'package:melody_meets/profile/provider/profile_provider.dart';
import 'package:melody_meets/profile/view/profile_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  static const routeName = '/search';

  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _showClearButton = false;

  // State for follow button
  bool _isProcessingFollow = false;
  String? _processingUserId;

  // Animation for better UI transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Add try-catch to prevent crashes during initialization
    try {
      // Load suggested users on start
      Future.microtask(() {
        if (mounted) {
          ref.read(userSearchProvider.notifier).getSuggestedUsers();
        }
      });

      // Set up listeners
      _searchController.addListener(() {
        if (mounted) {
          setState(() {
            _showClearButton = _searchController.text.isNotEmpty;
          });

          // Update search query provider
          ref.read(searchQueryProvider.notifier).state = _searchController.text;
        }
      });

      // Request focus for search field
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } catch (e) {
      debugPrint('Error in SearchScreen initialization: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (!mounted) return;

    final query = _searchController.text.trim();
    setState(() {
      _isSearching = true;
    });

    try {
      // Use Future to catch any async errors
      Future.microtask(() async {
        try {
          debugPrint('Query: $query');
          await ref.read(userSearchProvider.notifier).searchUsers(query);
        } catch (e) {
          debugPrint('Error in search operation: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Search failed. Please try again.'),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Error performing search: $e');
    }
  }

  void _clearSearch() {
    if (!mounted) return;

    _searchController.clear();
    _searchFocusNode.requestFocus();
    try {
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(userSearchProvider.notifier).getSuggestedUsers();
    } catch (e) {
      debugPrint('Error clearing search: $e');
    }
    setState(() {
      _isSearching = false;
    });
  }

  void _navigateToProfile(String? userId) async {
    if (userId != null && userId.isNotEmpty) {
      // Navigate to profile screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
      );

      // When returning from profile, refresh the search results to sync follow state
      if (mounted) {
        final currentQuery = ref.read(searchQueryProvider);
        if (currentQuery.isEmpty) {
          ref.read(userSearchProvider.notifier).getSuggestedUsers();
        } else {
          ref.read(userSearchProvider.notifier).searchUsers(currentQuery);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot view this profile'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Toggle follow status
  void _toggleFollow(String userId) async {
    // Prevent double-taps during processing
    if (_isProcessingFollow) return;

    try {
      // Set processing state
      setState(() {
        _isProcessingFollow = true;
        _processingUserId = userId;
      });

      // Call the toggle function in search provider
      await ref.read(userSearchProvider.notifier).toggleFollow(userId);

      // Check if there's an active profile provider for this user and sync it
      try {
        // This will sync the follow status in the profile provider if it exists
        final hasProfile = ref.exists(profileProvider(userId));
        if (hasProfile) {
          await ref
              .read(profileProvider(userId).notifier)
              .refreshFollowStatus();
          debugPrint(
            'Synced follow status with profile provider for user $userId',
          );
        }
      } catch (e) {
        debugPrint('Error syncing with profile provider: $e');
        // Continue normally as this is just a sync operation
      }

      // Reset state after operation completes
      if (mounted) {
        setState(() {
          _isProcessingFollow = false;
          _processingUserId = null;
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');

      // Reset state and show error
      if (mounted) {
        setState(() {
          _isProcessingFollow = false;
          _processingUserId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update follow status'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsState = ref.watch(userSearchProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Status bar space
            SizedBox(height: MediaQuery.of(context).padding.top),

            // Search header
            _buildSearchHeader(),

            // Main content
            Expanded(
              child: _buildPeopleResults(searchResultsState, searchQuery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 22,
                color: AppTheme.whiteColor,
              ),
              onPressed: () => Navigator.pop(context),
              splashRadius: 24,
            ),
          ),

          // Search field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.darkGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(left: 8),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: AppTheme.lightGrey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search users',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.lightGrey,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          counterText: '',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.whiteColor,
                        ),
                        textInputAction: TextInputAction.search,
                        showCursor: true,
                        cursorColor: AppTheme.primaryColor,
                        cursorWidth: 1.2,
                        onSubmitted: (_) => _performSearch(),
                        onChanged: (_) {
                          if (!_isSearching) {
                            setState(() {
                              _isSearching = true;
                            });
                          }
                        },
                      ),
                    ),
                    if (_showClearButton)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.mediumGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleResults(
    AsyncValue<List<UserWithFollowStatus>> searchResults,
    String query,
  ) {
    // Handle loading state
    if (searchResults is AsyncLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    // Handle error state
    if (searchResults is AsyncError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: AppTheme.lightGrey),
            const SizedBox(height: 16),
            Text(
              'Error loading results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.whiteColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try again later',
              style: TextStyle(fontSize: 14, color: AppTheme.lightGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.whiteColor,
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    // Get the actual data with null safety
    final users = searchResults.value ?? [];

    // Handle empty results
    if (users.isEmpty) {
      if (query.isNotEmpty) {
        // No results for search
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 60, color: AppTheme.lightGrey),
              const SizedBox(height: 24),
              Text(
                'No users found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.whiteColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(fontSize: 14, color: AppTheme.lightGrey),
              ),
            ],
          ),
        );
      } else {
        // No suggested users
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 60, color: AppTheme.lightGrey),
              const SizedBox(height: 24),
              Text(
                'No users to suggest yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.whiteColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Come back later',
                style: TextStyle(fontSize: 14, color: AppTheme.lightGrey),
              ),
            ],
          ),
        );
      }
    }

    // Display users in a Spotify-style list
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header - suggested or search results
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  query.isNotEmpty ? 'Search Results' : 'Suggested for You',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.whiteColor,
                  ),
                ),
                const Spacer(),
                // Number of results
                Text(
                  '${users.length} ${users.length == 1 ? 'user' : 'users'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.lightGrey,
                  ),
                ),
              ],
            ),
          ),
        ),

        // User list (Spotify style)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildUserListItem(users[index]),
              childCount: users.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(UserWithFollowStatus userWithStatus) {
    final user = userWithStatus.account;
    final isFollowing = userWithStatus.isFollowing;

    return InkWell(
      onTap: () => _navigateToProfile(user.id),
      splashColor: Colors.transparent,
      highlightColor: AppTheme.darkGrey.withOpacity(0.5),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // User Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child:
                    user.image_url == null || user.image_url!.isEmpty
                        ? Container(
                          color: AppTheme.mediumGrey,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: AppTheme.lightGrey,
                          ),
                        )
                        : CachedNetworkImage(
                          imageUrl: user.image_url!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: AppTheme.mediumGrey,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor,
                                    ),
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppTheme.mediumGrey,
                                child: Icon(
                                  Icons.error_outline,
                                  size: 30,
                                  color: AppTheme.lightGrey,
                                ),
                              ),
                        ),
              ),
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username ?? 'User',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  if (user.email != null && user.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Follow/Following button
            GestureDetector(
              onTap:
                  (_isProcessingFollow && _processingUserId == user.id)
                      ? null
                      : () => _toggleFollow(user.id!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isFollowing ? Colors.transparent : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isFollowing
                            ? AppTheme.lightGrey
                            : AppTheme.primaryColor,
                    width: 1,
                  ),
                ),
                child:
                    (_isProcessingFollow && _processingUserId == user.id)
                        ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFollowing
                                  ? AppTheme.lightGrey
                                  : AppTheme.whiteColor,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isFollowing
                                    ? AppTheme.lightGrey
                                    : AppTheme.whiteColor,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

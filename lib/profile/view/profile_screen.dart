import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/profile/provider/profile_provider.dart';
import 'package:melody_meets/profile/view/edit_profile_screen.dart';
import 'package:melody_meets/profile/widget/profile_account_sheet.dart';
import 'package:melody_meets/profile/widget/profile_header.dart';
import 'package:melody_meets/profile/widget/profile_tab_bar_delegate.dart';
import 'package:melody_meets/songs/api/song_repository.dart'
    show songRepositoryProvider;
import 'package:melody_meets/songs/widget/song_grid.dart';
import 'package:melody_meets/songs/widget/song_option_sheet.dart';
import 'package:melody_meets/songs/widget/song_player_modal.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:melody_meets/songs/view/create_song_screen.dart';
import 'package:melody_meets/songs/view/edit_song_screen.dart';
import 'package:melody_meets/home/provider/feed_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ProfileScreen displays a user's profile information and songs.
/// It follows Spotify's design patterns with tabs for songs and saved content.
class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Tab controller for songs/saved tabs
  late TabController _tabController;

  // Current user status
  bool _isCurrentUser = false;
  bool _isCurrentUserInitialized = false;
  bool _disposed = false;

  // Store auth repository locally
  AuthRepository? _authRepository;

  // Track when we're on the saved songs tab for auto-refresh
  bool _onSavedSongsTab = false;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 tabs: Songs and Saved
    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes to refresh saved songs when tab is selected
    _tabController.addListener(_onTabChanged);

    // Initialize auth repository and current user status
    _initializeUserData();

    // Listen for bookmark changes from other screens
    _setupBookmarkChangeListener();
  }

  void _onTabChanged() {
    // Check if we're now on the Saved Songs tab (index 1)
    final onSavedSongsTab = _tabController.index == 1;

    // If we just navigated to the Saved tab and we're the current user, refresh
    if (onSavedSongsTab && !_onSavedSongsTab && _isCurrentUser && !_disposed) {
      debugPrint('🔵 Tab changed to Saved Songs, refreshing bookmarks');
      ref.read(profileProvider(widget.userId).notifier).refreshSavedSongs();
    }

    // Update tab tracking state
    _onSavedSongsTab = onSavedSongsTab;
  }

  // Listen for bookmark changes from other screens (like Feed)
  void _setupBookmarkChangeListener() {
    // Setup one-time listener for bookmark changes in the feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(feedNotifier, (previous, current) {
        if (_disposed) return;

        if (current is AsyncData && previous is AsyncData) {
          final previousSongs = previous?.value ?? [];
          final currentSongs = current.value ?? [];

          bool bookmarkChanged = false;

          // Check if any bookmark status changed
          for (final currentSong in currentSongs) {
            final previousSong = previousSongs.firstWhere(
              (s) => s.id == currentSong.id,
              orElse: () => currentSong,
            );

            if (previousSong.isBookmarked != currentSong.isBookmarked) {
              bookmarkChanged = true;
              debugPrint(
                '🔵 Bookmark change detected in Feed: ${currentSong.id}',
              );
              break;
            }
          }

          // If bookmark status changed and we're viewing current user's profile, refresh saved songs
          if (bookmarkChanged && _isCurrentUser && !_disposed) {
            debugPrint('🔵 Refreshing profile saved songs due to feed change');
            ref
                .read(profileProvider(widget.userId).notifier)
                .refreshSavedSongs();
          }
        }
      });
    });
  }

  // Safe initialization method
  Future<void> _initializeUserData() async {
    if (mounted) {
      try {
        // Save local reference to auth repository
        _authRepository = ref.read(authRepositoryProvider);

        // Initialize isCurrentUser by safely reading from profile provider
        final profileNotifier = ref.read(
          profileProvider(widget.userId).notifier,
        );
        _isCurrentUser = profileNotifier.isCurrentUserProfile();
        _isCurrentUserInitialized = true;

        // Update UI if needed
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint('Error initializing profile data: $e');
        // Default to false for safety
        _isCurrentUser = false;
        _isCurrentUserInitialized = true;

        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure user data is initialized
    if (!_isCurrentUserInitialized) {
      _initializeUserData();

      // Show a loading indicator until initialization is complete
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Watch profile state changes
    final profileState = ref.watch(profileProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          // More options button
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showProfileOptions(),
          ),
          // Add refresh button for easier testing
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Force refresh profile and saved songs
                ref
                    .read(profileProvider(widget.userId).notifier)
                    .refreshProfile();
              },
            ),
        ],
      ),
      floatingActionButton: profileState.when(
        data: (state) {
          // Only show FAB for current user
          return _isCurrentUser ? _buildFloatingActionButton() : null;
        },
        loading: () => null,
        error: (_, __) => null,
      ),
      body: profileState.when(
        // Loading state
        loading: () => const Center(child: CircularProgressIndicator()),

        // Error state
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading profile
                      if (!_disposed && mounted) {
                        ref
                            .read(profileProvider(widget.userId).notifier)
                            .refreshProfile();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

        // Data loaded successfully
        data: (state) {
          if (state.user == null) {
            return const Center(child: Text('User not found'));
          }

          // Use NestedScrollView for collapsing header behavior
          return NestedScrollView(
            // Header sliver (profile info and tabs)
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Profile header section
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    user: state.user!,
                    state: state,
                    isCurrentUser: _isCurrentUser,
                    onEditProfile: () => _navigateToEditProfile(),
                    onToggleFollow: () => _toggleFollow(),
                  ),
                ),

                // Tab bar for songs/saved songs
                SliverPersistentHeader(
                  delegate: ProfileTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.lightGrey,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(icon: Icon(Icons.music_note)),
                        Tab(icon: Icon(Icons.bookmark_border)),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },

            // Tab view content
            body: TabBarView(
              controller: _tabController,
              children: [
                // Songs tab
                SongGrid(
                  songs: state.songs,
                  isCurrentUserProfile: _isCurrentUser,
                  onSongTap: (song) => _showSongDetails(song),
                  onSongOptionsTap:
                      _isCurrentUser ? (song) => _showSongOptions(song) : null,
                  onCreateSongTap:
                      _isCurrentUser ? () => _navigateToCreateSong() : null,
                  onLike: (song) => _handleLikeAction(song),
                  onBookmark: (song) => _handleBookmarkAction(song),
                ),

                // Saved songs tab - with real-time updates
                SongGrid(
                  songs: state.savedSongs,
                  isCurrentUserProfile: _isCurrentUser,
                  onSongTap: (song) => _showSongDetails(song),
                  onLike: (song) => _handleLikeAction(song),
                  onBookmark: (song) => _handleBookmarkAction(song),
                  onCreateSongTap: null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Centralized like handling
  void _handleLikeAction(Songs song) {
    if (!mounted || _disposed) return;

    // Toggle like in profile provider
    ref.read(profileProvider(widget.userId).notifier).toggleLike(song.id!);
  }

  // Centralized bookmark handling with real-time updates
  void _handleBookmarkAction(Songs song) {
    if (!mounted || _disposed) return;

    // Toggle bookmark in profile provider
    ref.read(profileProvider(widget.userId).notifier).toggleBookmark(song.id!);

    // Force immediate refresh of saved songs to ensure real-time updates
    Future.delayed(Duration.zero, () {
      if (!_disposed && mounted && _isCurrentUser) {
        ref.read(profileProvider(widget.userId).notifier).refreshSavedSongs();
      }
    });
  }

  /// Shows profile options in a bottom sheet
  void _showProfileOptions() {
    if (!mounted || _disposed) return;

    final isFollowing =
        ref.read(profileProvider(widget.userId)).value?.isFollowing ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ProfileActionsSheet(
            isCurrentUserProfile: _isCurrentUser,
            isFollowing: isFollowing,
            onEditProfileTap: () {
              Navigator.pop(context);
              _navigateToEditProfile();
            },
            onCreateSongTap: () {
              Navigator.pop(context);
              _navigateToCreateSong();
            },
            onLogoutTap: () {
              Navigator.pop(context);
              _logout();
            },
            onToggleFollowTap: () {
              Navigator.pop(context);
              _toggleFollow();
            },
          ),
    );
  }

  /// Shows song options for current user's songs
  void _showSongOptions(Songs song) {
    if (!mounted || _disposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SongOptionsSheet(
            onEditTap: () {
              Navigator.pop(context);
              _navigateToEditSong(song);
            },
            onDeleteTap: () {
              Navigator.pop(context);
              _confirmDeleteSong(song.id!);
            },
          ),
    );
  }

  /// Shows full song details and player
  void _showSongDetails(Songs song) {
    if (!mounted || _disposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SongPlayerModal(
            song: song,
            onSongLiked: (updatedSong) {
              if (!_disposed && mounted) {
                _handleLikeAction(updatedSong);
              }
            },
            onSongBookmarked: (updatedSong) {
              if (!_disposed && mounted) {
                _handleBookmarkAction(updatedSong);
              }
            },
          ),
    );
  }

  /// Shows confirmation dialog before deleting a song
  Future<void> _confirmDeleteSong(String songId) async {
    if (!mounted || _disposed) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkGrey,
          title: Text(
            'Delete Song',
            style: TextStyle(color: AppTheme.whiteColor),
          ),
          content: Text(
            'Are you sure you want to delete this song? This action cannot be undone.',
            style: TextStyle(color: AppTheme.lightGrey),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.lightGrey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSong(songId);
              },
            ),
          ],
        );
      },
    );
  }

  /// Deletes a song with error handling
  Future<void> _deleteSong(String songId) async {
    if (!mounted || _disposed) return;

    try {
      final songRepo = ref.read(songRepositoryProvider);
      await songRepo.deleteSong(songId);

      // Remove song from UI
      if (!_disposed && mounted) {
        ref.read(profileProvider(widget.userId).notifier).removeSong(songId);

        // Force a refresh after deletion to ensure UI consistency
        ref.read(profileProvider(widget.userId).notifier).refreshProfile();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song deleted successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (!_disposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete song: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Navigates to create song screen
  void _navigateToCreateSong() async {
    if (!mounted || _disposed) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSongScreen()),
    );

    if (result != null && result is Songs && !_disposed && mounted) {
      // Clear cache in song repository to force fresh data
      ref.read(songRepositoryProvider).clearCaches();

      // Add new song to the profile
      ref.read(profileProvider(widget.userId).notifier).addSong(result);

      // Schedule a background refresh after a delay to ensure DB consistency
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_disposed && mounted) {
          ref.read(profileProvider(widget.userId).notifier).refreshProfile();
        }
      });
    }
  }

  /// Navigates to edit song screen
  void _navigateToEditSong(Songs song) async {
    if (!mounted || _disposed) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditSongScreen(songId: song.id!)),
    );

    if (result != null && result is Songs && !_disposed && mounted) {
      // Clear cache in song repository to force fresh data
      ref.read(songRepositoryProvider).clearCaches();

      // Update song in the profile
      ref.read(profileProvider(widget.userId).notifier).updateSong(result);

      // Schedule additional refresh after a delay to ensure DB consistency
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_disposed && mounted) {
          ref.read(profileProvider(widget.userId).notifier).refreshProfile();
        }
      });
    }
  }

  /// Navigates to edit profile screen
  void _navigateToEditProfile() async {
    if (!mounted || _disposed) return;

    final user = ref.read(profileProvider(widget.userId)).value?.user;
    if (user != null) {
      await Navigator.push(
        context,
        // will implement the user id in the edit profile screen, later
        MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
      );

      // Refresh profile data
      if (!_disposed && mounted) {
        ref.read(profileProvider(widget.userId).notifier).refreshProfile();
      }
    }
  }

  /// Toggles follow state for this profile
  void _toggleFollow() async {
    if (!mounted || _disposed) return;

    // Disable UI during follow/unfollow operation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating follow status...'),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await ref.read(profileProvider(widget.userId).notifier).toggleFollow();

      // Refresh follow status after a short delay to ensure DB consistency
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_disposed && mounted) {
          ref
              .read(profileProvider(widget.userId).notifier)
              .refreshFollowStatus();
        }
      });
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating follow status: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Logs out current user
  void _logout() async {
    if (!mounted || _disposed) return;

    // Store navigation context locally to avoid context issues
    final BuildContext navigatorContext = context;

    try {
      // Mark as disposed to prevent further UI updates
      _disposed = true;

      // Create a local variable to use for navigation
      final navigator = Navigator.of(navigatorContext);

      // Clear the song repository cache before logout
      ref.read(songRepositoryProvider).clearCaches();

      // Use the locally stored repository reference instead of accessing through provider
      if (_authRepository != null) {
        await _authRepository!.logout();
      } else {
        // If auth repository wasn't initialized, try to get it now
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.logout();
      }

      // Navigate to login screen
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      // Reset disposed flag if error occurs
      _disposed = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Builds floating action button for creating new songs
  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _navigateToCreateSong,
        heroTag: 'profile_create_song_fab',
        elevation: 0,
        backgroundColor: Colors.transparent, // Use container's gradient
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

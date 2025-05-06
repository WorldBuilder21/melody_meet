import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/home/provider/feed_provider.dart';
import 'package:melody_meets/home/view/search_screen.dart';
import 'package:melody_meets/profile/provider/profile_provider.dart';
import 'package:melody_meets/profile/view/profile_screen.dart';
import 'package:melody_meets/songs/provider/song_state_provider.dart';

import 'package:melody_meets/songs/schema/songs.dart';
import 'package:melody_meets/songs/widget/feed_song_card.dart';
import 'package:melody_meets/songs/widget/song_player_modal.dart';
import 'package:melody_meets/video_call/model/live_stream.dart';
import 'package:melody_meets/video_call/view/start_stream_screen.dart';
import 'package:melody_meets/video_call/widget/live_stream_card.dart';

import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Create a provider for live streams that updates in real-time
final followedLiveStreamsProvider =
    StateNotifierProvider<LiveStreamNotifier, AsyncValue<List<LiveStream>>>((
      ref,
    ) {
      return LiveStreamNotifier(ref);
    });

// State notifier that manages live streams and handles real-time updates
class LiveStreamNotifier extends StateNotifier<AsyncValue<List<LiveStream>>> {
  final Ref ref;
  RealtimeChannel? _channel;
  List<String>? _followingIds;

  LiveStreamNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initializeFollowingAndStreams();
  }

  // Initialize with following IDs and then fetch streams
  Future<void> _initializeFollowingAndStreams() async {
    try {
      await _fetchFollowingIds();
      await _fetchLiveStreams();
      _setupRealtimeSubscription();
    } catch (e) {
      debugPrint('Error initializing live streams: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Fetch following IDs separately
  Future<void> _fetchFollowingIds() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _followingIds = [];
      return;
    }

    try {
      // Get followed users
      final followingResponse = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      _followingIds =
          followingResponse
              .map((follow) => follow['following_id'] as String)
              .toList();

      debugPrint('🔴 Following ${_followingIds!.length} users: $_followingIds');
    } catch (e) {
      debugPrint('🔴 Error fetching following IDs: $e');
      _followingIds = [];
    }
  }

  // Fetch live streams of followed users
  Future<void> _fetchLiveStreams() async {
    if (_followingIds == null || _followingIds!.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      // IMPORTANT: Set state to loading so UI shows loading indicator
      state = const AsyncValue.loading();

      debugPrint('🔴 Querying live streams for users: $_followingIds');

      // Get active live streams - DO NOT FILTER BY has_host_connected YET
      final response = await Supabase.instance.client
          .from('live_streams')
          .select('''
            *,
            accounts!inner(
              id, 
              username, 
              email, 
              image_url, 
              created_at
            )
          ''')
          .eq('is_active', true)
          .inFilter('user_id', _followingIds!)
          .order('created_at', ascending: false);

      // Debug ALL streams before filtering
      final allStreams =
          response.map((data) => LiveStream.fromJson(data)).toList();
      debugPrint('🔴 Found ${allStreams.length} active streams total');
      for (final stream in allStreams) {
        debugPrint(
          '🔴 Stream ${stream.id}: has_host_connected=${stream.has_host_connected}',
        );
      }

      // Now filter by has_host_connected to get final list
      final liveStreams =
          allStreams
              .where((stream) => stream.has_host_connected == true)
              .toList();

      debugPrint(
        '🔴 After filtering, showing ${liveStreams.length} streams with connected hosts',
      );
      state = AsyncValue.data(liveStreams);
    } catch (e) {
      debugPrint('🔴 Error fetching live streams: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Set up real-time subscription that listens to ALL changes
  void _setupRealtimeSubscription() {
    // First unsubscribe from any existing channel
    _channel?.unsubscribe();

    // Create a single channel with multiple listeners
    final channel = Supabase.instance.client.channel('db-changes');

    // Add subscription for live_streams table changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'live_streams',
      callback: (payload) {
        debugPrint('🔴 LIVE STREAM INSERTED: ${payload.newRecord}');
        _fetchLiveStreams();
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'live_streams',
      callback: (payload) {
        debugPrint('🔴 LIVE STREAM UPDATED: ${payload.newRecord}');
        _fetchLiveStreams();
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'live_streams',
      callback: (payload) {
        debugPrint('🔴 LIVE STREAM DELETED');
        _fetchLiveStreams();
      },
    );

    // Subscribe to the channel
    channel.subscribe((status, [error]) {
      debugPrint('🔴 Subscription status: $status, Error: $error');
    });

    _channel = channel;
  }

  // Refresh live streams manually
  Future<void> refresh() async {
    await _fetchFollowingIds();
    await _fetchLiveStreams();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  // For smoother scrolling
  final ScrollController _scrollController = ScrollController();

  // Add a flag to track whether first load has completed
  bool _initialLoadComplete = false;

  // Track if we're coming back from another screen
  bool _returnedToScreen = false;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to schedule initialization after build
    Future.microtask(() => _initializeFeed());

    // Set up a scroll listener for more efficient infinite scrolling
    _scrollController.addListener(_scrollListener);
  }

  // More efficient initialization
  Future<void> _initializeFeed() async {
    if (!mounted) return;

    // Only show loading indicator on first load
    try {
      await ref.read(feedNotifier.notifier).loadFeed();
      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial feed: $e');
      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    }
  }

  // Add a scroll listener for more efficient loading
  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // Load more songs when near the bottom (80% of the way down)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll > threshold) {
      // Load more songs if not already loading
      _loadMoreSongsIfNeeded();
    }
  }

  // Check if we should load more songs
  Future<void> _loadMoreSongsIfNeeded() async {
    final feedState = ref.read(feedNotifier);

    // Only try to load more if we have data and aren't already loading
    if (feedState is AsyncData && !_refreshController.isLoading) {
      await ref.read(feedNotifier.notifier).loadMoreSongs();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we're returning to this screen
    if (_initialLoadComplete && !_returnedToScreen) {
      _returnedToScreen = true;

      // Refresh the feed when coming back to this screen
      Future.microtask(() {
        if (mounted) {
          _onRefresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    try {
      // Clear scroll position
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      // Refresh live streams
      await ref.read(followedLiveStreamsProvider.notifier).refresh();

      // Refresh feed
      await ref.read(feedNotifier.notifier).refreshFeed();

      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        _refreshController.refreshFailed();
        debugPrint('Refresh failed: $e');
      }
    }
  }

  Future<void> _onLoading() async {
    try {
      await ref.read(feedNotifier.notifier).loadMoreSongs();
      if (mounted) {
        _refreshController.loadComplete();
      }
    } catch (e) {
      if (mounted) {
        _refreshController.loadFailed();
        debugPrint('Load more failed: $e');
      }
    }
  }

  void _navigateToSearch() {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
          maintainState: false,
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open search. Please try again.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint('Building HomeScreen');
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Melody Meets',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.whiteColor, size: 26),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: true,
        header: WaterDropHeader(
          waterDropColor: AppTheme.primaryColor,
          complete: Icon(Icons.check, color: AppTheme.primaryColor),
          refresh: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        footer: CustomFooter(
          builder: (context, mode) {
            Widget body;
            if (mode == LoadStatus.idle) {
              body = Text(
                "Pull up to load more",
                style: TextStyle(color: AppTheme.lightGrey, fontSize: 13),
              );
            } else if (mode == LoadStatus.loading) {
              body = CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                strokeWidth: 2.0,
              );
            } else if (mode == LoadStatus.failed) {
              body = Text(
                "Failed to load. Tap to retry!",
                style: TextStyle(color: AppTheme.lightGrey, fontSize: 13),
              );
            } else if (mode == LoadStatus.canLoading) {
              body = Text(
                "Release to load more",
                style: TextStyle(color: AppTheme.lightGrey, fontSize: 13),
              );
            } else {
              body = Text(
                "No more songs",
                style: TextStyle(color: AppTheme.lightGrey, fontSize: 13),
              );
            }
            return Container(
              height: 55.0,
              padding: const EdgeInsets.only(bottom: 15),
              child: Center(child: body),
            );
          },
        ),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final feedState = ref.watch(feedNotifier);
    final liveStreamsState = ref.watch(followedLiveStreamsProvider);

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: liveStreamsState.when(
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error: (error, stack) {
              debugPrint('Error loading live streams: $error');
              return const SizedBox.shrink();
            },
            data: (liveStreams) {
              if (liveStreams.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live Now',
                          style: TextStyle(
                            color: AppTheme.whiteColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.videocam),
                          label: const Text('Go Live'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StartStreamScreen(),
                              ),
                            ).then((_) {
                              // Refresh live streams when returning
                              ref
                                  .read(followedLiveStreamsProvider.notifier)
                                  .refresh();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: liveStreams.length,
                    itemBuilder: (context, index) {
                      return LiveStreamCard(liveStream: liveStreams[index]);
                    },
                  ),
                  const Divider(height: 1, thickness: 1),
                ],
              );
            },
          ),
        ),
        // Songs section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: feedState.when(
            loading: () {
              // Only show loading state on initial load
              if (_initialLoadComplete) {
                // If we've loaded before, show last known data during refresh
                final lastData = ref.read(feedNotifier).value ?? [];
                if (lastData.isNotEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = lastData[index];
                      return FeedSongCard(
                        song: song,
                        onLike:
                            () => ref
                                .read(feedNotifier.notifier)
                                .toggleLike(song.id!),
                        onBookmark: () {
                          ref
                              .read(feedNotifier.notifier)
                              .toggleBookmark(song.id!);
                          ref.invalidate(profileProvider(song.user_id!));
                          ref.invalidate(songStateProvider(song.id!));
                        },
                        onProfileTap: (id) => _navigateToProfile(context, id),
                        onTap: () => _showSongPlayer(song),
                      );
                    }, childCount: lastData.length),
                  );
                }
              }

              // Otherwise show shimmer loading state
              debugPrint('Rendering loading state...');
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const SongShimmerLoading(),
                  childCount: 3,
                ),
              );
            },
            error: (error, stackTrace) {
              debugPrint('Rendering error state: $error');
              return SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 50,
                          color: AppTheme.lightGrey,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Could not load songs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh and try again',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightGrey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Try Again'),
                          onPressed:
                              () =>
                                  ref.read(feedNotifier.notifier).refreshFeed(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.whiteColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            data: (songs) {
              debugPrint('Rendering songs: ${songs.length}');

              // Set flag to indicate data has been loaded
              if (!_initialLoadComplete) {
                _initialLoadComplete = true;
              }

              if (songs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 70,
                            color: AppTheme.lightGrey,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No songs yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.whiteColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Follow artists to see their songs here',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.lightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return FeedSongCard(
                    song: song,
                    onLike: () {
                      ref.read(feedNotifier.notifier).toggleLike(song.id!);
                      ref.invalidate(profileProvider(song.user_id!));
                      ref.invalidate(songStateProvider(song.id!));
                    },
                    onBookmark: () {
                      ref.read(feedNotifier.notifier).toggleBookmark(song.id!);
                      ref.invalidate(profileProvider(song.user_id!));
                      ref.invalidate(songStateProvider(song.id!));
                    },
                    onProfileTap: (id) => _navigateToProfile(context, id),
                    onTap: () => _showSongPlayer(song),
                  );
                }, childCount: songs.length),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    ).then((value) {
      // Set flag to indicate we've returned to this screen
      _returnedToScreen = true;

      // Refresh the feed when returning from profile
      _onRefresh();
    });
  }

  void _showSongPlayer(Songs song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SongPlayerModal(
            song: song,
            onSongLiked: (updatedSong) {
              ref.read(feedNotifier.notifier).toggleLike(updatedSong.id!);
            },
            onSongBookmarked: (updatedSong) {
              ref.read(feedNotifier.notifier).toggleBookmark(updatedSong.id!);
            },
          ),
    );
  }
}

class SongShimmerLoading extends StatelessWidget {
  const SongShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Cover Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),

          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGrey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),

          // Play Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

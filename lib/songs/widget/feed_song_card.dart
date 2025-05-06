import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:melody_meets/songs/provider/song_state_provider.dart';

class FeedSongCard extends ConsumerWidget {
  final Songs song;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final Function(String) onProfileTap;
  final VoidCallback onTap;

  const FeedSongCard({
    super.key,
    required this.song,
    required this.onLike,
    required this.onBookmark,
    required this.onProfileTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the song state from the provider
    final songState = ref.watch(songStateProvider(song.id!));

    // Use the latest state from the provider, falling back to the passed song if not available
    final currentSong = songState ?? song;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  currentSong.image_url != null
                      ? CachedNetworkImage(
                        imageUrl: currentSong.image_url!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              width: 80,
                              height: 80,
                              color: AppTheme.mediumGrey,
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  color: AppTheme.lightGrey,
                                  size: 30,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              width: 80,
                              height: 80,
                              color: AppTheme.mediumGrey,
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  color: AppTheme.lightGrey,
                                  size: 30,
                                ),
                              ),
                            ),
                      )
                      : Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.mediumGrey,
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            color: AppTheme.lightGrey,
                            size: 30,
                          ),
                        ),
                      ),
            ),
            const SizedBox(width: 16),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song Title
                  Text(
                    currentSong.title ?? 'Untitled',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Artist Name - Tappable to navigate to profile
                  GestureDetector(
                    onTap: () => onProfileTap(currentSong.user_id!),
                    child: Text(
                      currentSong.artist ?? 'Unknown Artist',
                      style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Genre Tag
                  if (currentSong.genre != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentSong.genre!,
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Like and Bookmark Row
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Like Button
                      GestureDetector(
                        onTap: () {
                          onLike();
                          // Update the song state in the provider
                          ref
                              .read(songStateProvider(currentSong.id!).notifier)
                              .toggleLike();
                        },
                        child: Icon(
                          currentSong.isLiked ?? false
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              currentSong.isLiked ?? false
                                  ? AppTheme.primaryColor
                                  : AppTheme.lightGrey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Bookmark Button
                      GestureDetector(
                        onTap: () {
                          onBookmark();
                          // Update the song state in the provider
                          ref
                              .read(songStateProvider(currentSong.id!).notifier)
                              .toggleBookmark();
                        },
                        child: Icon(
                          currentSong.isBookmarked ?? false
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color:
                              currentSong.isBookmarked ?? false
                                  ? AppTheme.primaryColor
                                  : AppTheme.lightGrey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Play Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

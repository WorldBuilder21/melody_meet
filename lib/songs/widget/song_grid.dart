import 'package:flutter/material.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/songs/widget/feed_song_card.dart';
import 'package:melody_meets/songs/schema/songs.dart';

class SongGrid extends StatelessWidget {
  final List<Songs> songs;
  final bool isCurrentUserProfile;
  final Function(Songs) onSongTap;
  final Function(Songs)? onSongOptionsTap;
  final VoidCallback? onCreateSongTap;
  final Function(Songs)? onLike;
  final Function(Songs)? onBookmark;

  const SongGrid({
    super.key,
    required this.songs,
    required this.isCurrentUserProfile,
    required this.onSongTap,
    this.onSongOptionsTap,
    this.onCreateSongTap,
    this.onLike,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return songs.isEmpty
        ? _buildEmptySongsList()
        : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return FeedSongCard(
              song: song,
              onTap: () => onSongTap(song),
              onLike: () => onLike?.call(song),
              onBookmark: () => onBookmark?.call(song),
              onProfileTap:
                  (_) {}, // No need to navigate to own profile in profile view
            );
          },
        );
  }

  Widget _buildEmptySongsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 64, color: AppTheme.lightGrey),
          const SizedBox(height: 24),
          Text(
            isCurrentUserProfile
                ? 'You haven\'t uploaded any songs yet'
                : 'No songs found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.whiteColor,
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrentUserProfile && onCreateSongTap != null)
            ElevatedButton(
              onPressed: onCreateSongTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Create Your First Song',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

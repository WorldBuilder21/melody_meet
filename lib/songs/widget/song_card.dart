import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/songs/schema/songs.dart';

class SongCard extends StatelessWidget {
  final Songs song;
  final VoidCallback onTap;
  final VoidCallback? onOptionsTap;

  const SongCard({
    Key? key,
    required this.song,
    required this.onTap,
    this.onOptionsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  // Song Cover Image
                  song.image_url != null
                      ? CachedNetworkImage(
                        imageUrl: song.image_url!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              height: 140,
                              color: AppTheme.mediumGrey,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              height: 140,
                              color: AppTheme.mediumGrey,
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 50,
                                  color: AppTheme.lightGrey,
                                ),
                              ),
                            ),
                      )
                      : Container(
                        height: 140,
                        color: AppTheme.mediumGrey,
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            size: 50,
                            color: AppTheme.lightGrey,
                          ),
                        ),
                      ),

                  // Options button (if provided)
                  if (onOptionsTap != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onOptionsTap,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  // Play button overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Song Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song Title
                  Text(
                    song.title ?? 'Untitled',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Artist Name
                  Text(
                    song.artist ?? 'Unknown Artist',
                    style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Genre Tag
                  if (song.genre != null)
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
                        song.genre!,
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

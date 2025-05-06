import 'package:flutter/material.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:melody_meets/video_call/model/live_stream.dart';
import 'package:melody_meets/video_call/view/viewer_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class LiveStreamCard extends StatelessWidget {
  final LiveStream liveStream;

  const LiveStreamCard({super.key, required this.liveStream});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewerScreen(liveStream: liveStream),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Thumbnail with live badge
            Stack(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child:
                        liveStream.thumbnail_url != null
                            ? CachedNetworkImage(
                              imageUrl: liveStream.thumbnail_url!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: AppTheme.darkColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.primaryColor,
                                            ),
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: AppTheme.darkColor,
                                    child: Center(
                                      child: Icon(
                                        Icons.live_tv,
                                        color: AppTheme.lightGrey,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                            )
                            : Container(
                              color: AppTheme.darkColor,
                              child: Center(
                                child: Icon(
                                  Icons.live_tv,
                                  color: AppTheme.lightGrey,
                                  size: 40,
                                ),
                              ),
                            ),
                  ),
                ),
                // Live badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Viewer count
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${liveStream.viewer_count ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            liveStream.user?.image_url != null
                                ? NetworkImage(liveStream.user!.image_url!)
                                : null,
                        backgroundColor: AppTheme.mediumGrey,
                        child:
                            liveStream.user?.image_url == null
                                ? Icon(
                                  Icons.person,
                                  color: AppTheme.lightGrey,
                                  size: 16,
                                )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        liveStream.user?.username ?? 'Artist',
                        style: TextStyle(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Time ago
                      Text(
                        timeago.format(liveStream.created_at!),
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Stream title
                  Text(
                    liveStream.title ?? 'Live Stream',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (liveStream.description != null &&
                      liveStream.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        liveStream.description!,
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

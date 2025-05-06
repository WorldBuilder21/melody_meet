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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewerScreen(liveStream: liveStream),
          ),
        );
      },
      child: Container(
        width: double.infinity, // Take full width
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with badges
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
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
                                      child: const Center(
                                        child: Icon(
                                          Icons.live_tv,
                                          color: Colors.white54,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                              )
                              : Container(
                                color: AppTheme.darkColor,
                                child: const Center(
                                  child: Icon(
                                    Icons.live_tv,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                ),
                              ),
                    ),
                  ),

                  // Overlay badges
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Live badge
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

                        // Viewer count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content section - using a more flexible layout
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stream title
                  Text(
                    liveStream.title ?? 'Live Stream',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description if available
                  if (liveStream.description != null &&
                      liveStream.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        liveStream.description!,
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // User info at bottom - using ListTile for better layout
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
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
                    title: Text(
                      liveStream.user?.username ?? 'Artist',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      timeago.format(liveStream.created_at!),
                      style: TextStyle(color: AppTheme.lightGrey, fontSize: 12),
                    ),
                    dense: true,
                    minLeadingWidth: 32,
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

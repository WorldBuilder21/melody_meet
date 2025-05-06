import 'package:flutter/material.dart';
import 'package:melody_meets/auth/schemas/account.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/profile/model/profile_state.dart';

class ProfileHeader extends StatelessWidget {
  final Account user;
  final ProfileState state;
  final bool isCurrentUser;
  final VoidCallback onEditProfile;
  final VoidCallback onToggleFollow;

  const ProfileHeader({
    Key? key,
    required this.user,
    required this.state,
    required this.isCurrentUser,
    required this.onEditProfile,
    required this.onToggleFollow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture and statistics
          Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor,
                backgroundImage:
                    user.image_url != null
                        ? NetworkImage(user.image_url!)
                        : null,
                child:
                    user.image_url == null
                        ? Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.whiteColor,
                        )
                        : null,
              ),

              const SizedBox(width: 24),

              // Statistics
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Songs count
                    _buildStatColumn(
                      context,
                      state.songs.length.toString(),
                      'Songs',
                    ),

                    // Followers count
                    _buildStatColumn(
                      context,
                      state.followerCount.toString(),
                      'Followers',
                    ),

                    // Following count
                    _buildStatColumn(
                      context,
                      state.followingCount.toString(),
                      'Following',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Username and bio
          Text(
            user.username ?? 'User',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              user.bio!,
              style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
            ),
          ],

          const SizedBox(height: 20),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child:
                isCurrentUser
                    ? ElevatedButton(
                      onPressed: onEditProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkGrey,
                        foregroundColor: AppTheme.whiteColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    )
                    : ElevatedButton(
                      onPressed: onToggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            state.isFollowing
                                ? AppTheme.darkGrey
                                : AppTheme.primaryColor,
                        foregroundColor: AppTheme.whiteColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(state.isFollowing ? 'Following' : 'Follow'),
                    ),
          ),

          const SizedBox(height: 16),

          // Verification badge if user is verified
          if (user.is_verified == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Verified Artist',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: AppTheme.whiteColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppTheme.lightGrey, fontSize: 14)),
      ],
    );
  }
}

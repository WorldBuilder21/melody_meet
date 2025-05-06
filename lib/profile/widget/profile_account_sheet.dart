import 'package:flutter/material.dart';
import 'package:melody_meets/config/theme.dart';

class ProfileActionsSheet extends StatelessWidget {
  final bool isCurrentUserProfile;
  final bool isFollowing;
  final VoidCallback onEditProfileTap;
  final VoidCallback onCreateSongTap;
  final VoidCallback onLogoutTap;
  final VoidCallback onToggleFollowTap;

  const ProfileActionsSheet({
    super.key,
    required this.isCurrentUserProfile,
    required this.isFollowing,
    required this.onEditProfileTap,
    required this.onCreateSongTap,
    required this.onLogoutTap,
    required this.onToggleFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isCurrentUserProfile ? 'Profile Options' : 'Actions',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          if (isCurrentUserProfile) ...[
            // Edit Profile Option
            ListTile(
              leading: Icon(Icons.person_outline, color: AppTheme.primaryColor),
              title: Text(
                'Edit Profile',
                style: TextStyle(color: AppTheme.whiteColor, fontSize: 16),
              ),
              onTap: onEditProfileTap,
            ),

            const Divider(color: AppTheme.mediumGrey),

            // Create Song Option
            ListTile(
              leading: Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                'Create New Song',
                style: TextStyle(color: AppTheme.whiteColor, fontSize: 16),
              ),
              onTap: onCreateSongTap,
            ),

            const Divider(color: AppTheme.mediumGrey),

            // Logout Option
            ListTile(
              leading: Icon(Icons.logout, color: AppTheme.lightGrey),
              title: Text(
                'Logout',
                style: TextStyle(color: AppTheme.whiteColor, fontSize: 16),
              ),
              onTap: onLogoutTap,
            ),
          ] else ...[
            // Follow/Unfollow Option
            ListTile(
              leading: Icon(
                isFollowing
                    ? Icons.person_remove_outlined
                    : Icons.person_add_outlined,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                isFollowing ? 'Unfollow' : 'Follow',
                style: TextStyle(color: AppTheme.whiteColor, fontSize: 16),
              ),
              onTap: onToggleFollowTap,
            ),
          ],

          const SizedBox(height: 24),

          // Cancel Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.darkColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Safe area padding at bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

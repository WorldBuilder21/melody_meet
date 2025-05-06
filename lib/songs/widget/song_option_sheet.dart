import 'package:flutter/material.dart';
import 'package:melody_meets/config/theme.dart';

class SongOptionsSheet extends StatelessWidget {
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const SongOptionsSheet({
    super.key,
    required this.onEditTap,
    required this.onDeleteTap,
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
            'Song Options',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Edit Option
          ListTile(
            leading: Icon(Icons.edit, color: AppTheme.primaryColor),
            title: Text(
              'Edit Song',
              style: TextStyle(color: AppTheme.whiteColor, fontSize: 16),
            ),
            onTap: onEditTap,
          ),

          const Divider(color: AppTheme.mediumGrey),

          // Delete Option
          ListTile(
            leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
            title: Text(
              'Delete Song',
              style: TextStyle(color: AppTheme.errorColor, fontSize: 16),
            ),
            onTap: onDeleteTap,
          ),

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

import 'package:flutter/material.dart';
import 'package:melody_meets/config/theme.dart';

class ImprovedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const ImprovedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Increased icon size for better visibility
    const double iconSize = 28.0;

    // Define nav items with consistent icon sizing
    final List<Map<String, dynamic>> navItems = [
      {
        'label': 'Home',
        'activeIcon': Icons.home,
        'inactiveIcon': Icons.home_outlined,
      },

      {
        'label': 'Video',
        'activeIcon': Icons.video_call,
        'inactiveIcon': Icons.video_call_outlined,
      },
      {
        'label': 'Profile',
        'activeIcon': Icons.person,
        'inactiveIcon': Icons.person_outline,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkGrey, // Spotify-inspired dark theme
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        // Add SafeArea to handle bottom insets properly
        child: Container(
          height: 80, // Increased height for better touch targets
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              navItems.length,
              (index) => _buildNavItem(
                context,
                index,
                navItems[index]['label'],
                navItems[index]['activeIcon'],
                navItems[index]['inactiveIcon'],
                false, // No badges needed for this app
                iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build each nav item with consistent styling and size
  Widget _buildNavItem(
    BuildContext context,
    int index,
    String label,
    IconData activeIcon,
    IconData inactiveIcon,
    bool hasBadge,
    double iconSize,
  ) {
    final bool isSelected = currentIndex == index;

    // Calculate the width to ensure equal spacing
    final width = MediaQuery.of(context).size.width / 4; // 4 tabs instead of 5

    // Base nav item with fixed width for consistency
    Widget item = Container(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with increased size
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: iconSize,
              color:
                  isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.lightGrey, // Spotify colors
            ),
          ),

          // Add spacing
          const SizedBox(height: 5),

          // Label - only visible when selected
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isSelected ? 18 : 0,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor, // Spotify green
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap in InkWell for tap handling with consistent sizing
    return InkWell(
      onTap: () => onTabTapped(index),
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: item,
    );
  }
}

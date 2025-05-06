import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/config/theme.dart';

import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/core/widget/improved_bottom_nav.dart';
import 'package:melody_meets/home/home.dart';
import 'package:melody_meets/profile/view/profile_screen.dart';
import 'package:melody_meets/songs/view/create_song_screen.dart';
import 'package:melody_meets/video_call/view/start_stream_screen.dart';

class Layout extends ConsumerStatefulWidget {
  static const routeName = '/layout';
  const Layout({super.key});

  @override
  ConsumerState<Layout> createState() => _LayoutState();
}

class _LayoutState extends ConsumerState<Layout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  // For smooth transition animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);

    // Animation controller for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Initialize the audio player or other services when layout loads
    debugPrint('Initializing layout and audio player');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Change page when tapping on bottom nav bar item with smooth transition
  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    // Animate page transition
    _animationController.reset();
    _pageController.jumpToPage(_currentIndex);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building Layout with currentIndex: $_currentIndex');

    // Get current user ID for profile page
    final authRepo = ref.read(authRepositoryProvider);
    String userId;

    try {
      userId = authRepo.userId;
      debugPrint('Current user ID: $userId');
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      userId = '';
    }

    // Only show FAB on Home screen to create new song
    final bool showFab = _currentIndex == 0;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            // Main screens
            const HomeScreen(), // Index 0 - Home screen to see followed users' audio files

            StartStreamScreen(
              // userId: userId,
            ), // Index 2 - Video call screen (with verification check)
            ProfileScreen(
              userId: userId,
            ), // Index 3 - Profile screen showing user's songs
          ],
        ),
      ),
      extendBody: true, // Make bottom nav bar float over content
      // Using improved bottom navigation bar
      bottomNavigationBar: ImprovedBottomNavBar(
        currentIndex: _currentIndex,
        onTabTapped: _onTabTapped,
      ),
      floatingActionButton: showFab ? _buildFloatingActionButton() : null,
    );
  }

  // Floating action button for creating new audio
  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Navigate to create audio screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSongScreen()),
          );
        },
        heroTag: 'create_audio',
        elevation: 0,
        backgroundColor: Colors.transparent, // Use container's gradient
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

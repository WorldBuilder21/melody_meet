import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/songs/model/song_comment.dart';
import 'package:melody_meets/songs/provider/comment_provider.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';

class SongCommentsScreen extends ConsumerStatefulWidget {
  final Songs song;

  const SongCommentsScreen({super.key, required this.song});

  @override
  ConsumerState<SongCommentsScreen> createState() => _SongCommentsScreenState();
}

class _SongCommentsScreenState extends ConsumerState<SongCommentsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  File? _imageFile;
  bool _isLoadingLocation = false;
  LocationData? _locationData;
  final Location _location = Location();

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Request location permissions
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Check and request location permissions
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationData = await _location.getLocation();
      setState(() {
        _locationData = locationData;
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get your location'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to pick image'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Take a picture with camera
  Future<void> _takePhoto() async {
    try {
      final takenImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (takenImage != null) {
        setState(() {
          _imageFile = File(takenImage.path);
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to take photo'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Show image source dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Camera option
                  ListTile(
                    leading: Icon(
                      Icons.camera_alt,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Take Photo',
                      style: TextStyle(color: AppTheme.whiteColor),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: AppTheme.darkGrey,
                  ),
                  const SizedBox(height: 10),

                  // Gallery option
                  ListTile(
                    leading: Icon(
                      Icons.photo_library,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Choose from Gallery',
                      style: TextStyle(color: AppTheme.whiteColor),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: AppTheme.darkGrey,
                  ),
                  const SizedBox(height: 10),

                  // Cancel option
                  ListTile(
                    leading: Icon(Icons.close, color: AppTheme.lightGrey),
                    title: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.whiteColor),
                    ),
                    onTap: () => Navigator.pop(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: AppTheme.darkGrey,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Helper method for avatar images
  Widget _buildAvatarImage(String? imageUrl, double radius) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.mediumGrey,
        child: Icon(
          Icons.person,
          size: radius * 0.8,
          color: AppTheme.lightGrey,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => CircleAvatar(
                radius: radius,
                backgroundColor: AppTheme.mediumGrey,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    strokeWidth: 2.0,
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => CircleAvatar(
                radius: radius,
                backgroundColor: AppTheme.mediumGrey,
                child: Icon(
                  Icons.person,
                  size: radius * 0.8,
                  color: AppTheme.lightGrey,
                ),
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider(widget.song.id!));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Song summary card
          _buildSongSummary(),

          // Comments list
          Expanded(
            child: commentsState.when(
              loading:
                  () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
              error: (error, stackTrace) {
                debugPrint('Error loading comments: $error');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 50,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try again',
                          style: TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Try Again'),
                          onPressed:
                              () =>
                                  ref
                                      .read(
                                        commentsProvider(
                                          widget.song.id!,
                                        ).notifier,
                                      )
                                      .loadComments(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.whiteColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              data: (comments) {
                if (comments.isEmpty) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 60,
                            color: AppTheme.lightGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.whiteColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SlideTransition(
                  position: _slideAnimation,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: comments.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder:
                        (context, index) => _buildCommentItem(comments[index]),
                  ),
                );
              },
            ),
          ),

          // Comment input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildSongSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        border: Border(
          bottom: BorderSide(color: AppTheme.mediumGrey.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Song cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                widget.song.image_url != null
                    ? CachedNetworkImage(
                      imageUrl: widget.song.image_url!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: AppTheme.mediumGrey,
                            child: const Icon(
                              Icons.music_note,
                              color: AppTheme.lightGrey,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: AppTheme.mediumGrey,
                            child: const Icon(
                              Icons.music_note,
                              color: AppTheme.lightGrey,
                            ),
                          ),
                    )
                    : Container(
                      width: 50,
                      height: 50,
                      color: AppTheme.mediumGrey,
                      child: const Icon(
                        Icons.music_note,
                        color: AppTheme.lightGrey,
                      ),
                    ),
          ),
          const SizedBox(width: 12),

          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title ?? 'Untitled',
                  style: TextStyle(
                    color: AppTheme.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.song.artist ?? 'Unknown Artist',
                  style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCurrentUserComment = comment.user.id == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.darkGrey, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row with timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User avatar
              _buildAvatarImage(comment.user.image_url, 18),
              const SizedBox(width: 12),

              // Username and timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user.username ?? 'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.whiteColor,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          timeago.format(comment.createdAt, locale: 'en_short'),
                          style: TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: 12,
                          ),
                        ),

                        // Location indicator if available
                        if (comment.location != null)
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppTheme.lightGrey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                comment.location!,
                                style: TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Options menu (for own comments)
              if (isCurrentUserComment)
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.lightGrey,
                    size: 20,
                  ),
                  onPressed: () => _showCommentOptions(comment.id),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),

          // Comment content if not empty
          if (comment.hasContent)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8, right: 8),
              child: Text(
                comment.content!,
                style: TextStyle(fontSize: 15, color: AppTheme.whiteColor),
              ),
            ),

          // Comment image if available
          if (comment.hasCommentImage)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8, right: 8),
              child: GestureDetector(
                onTap: () {
                  // Show full screen image view
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              iconTheme: const IconThemeData(
                                color: Colors.white,
                              ),
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                child: CachedNetworkImage(
                                  imageUrl: comment.comment_image_url!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: comment.comment_image_url!,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 200,
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
                          height: 200,
                          color: AppTheme.mediumGrey,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppTheme.lightGrey,
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),

          // Like button and count
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8),
            child: Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: () => _toggleLike(comment.id),
                  child: Row(
                    children: [
                      Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color:
                            comment.isLiked
                                ? AppTheme.primaryColor
                                : AppTheme.lightGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comment.likes > 0 ? '${comment.likes}' : 'Like',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              comment.isLiked
                                  ? AppTheme.primaryColor
                                  : AppTheme.lightGrey,
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
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Preview of selected image if any
            if (_imageFile != null)
              Stack(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.darkColor.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Location indicator if any
            if (_locationData != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.darkColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location: ${_locationData!.latitude!.toStringAsFixed(4)}, ${_locationData!.longitude!.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.whiteColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _locationData = null;
                        });
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.lightGrey,
                      ),
                    ),
                  ],
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAvatarImage(
                  Supabase
                      .instance
                      .client
                      .auth
                      .currentUser
                      ?.userMetadata?['image_url'],
                  18,
                ),
                const SizedBox(width: 12),

                // Comment text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: AppTheme.lightGrey),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 14,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ),

                        // Location button
                        IconButton(
                          icon: Icon(
                            Icons.location_on,
                            color:
                                _locationData != null
                                    ? AppTheme.primaryColor
                                    : AppTheme.lightGrey,
                            size: 20,
                          ),
                          onPressed:
                              _isLoadingLocation
                                  ? null
                                  : _locationData != null
                                  ? () {
                                    setState(() {
                                      _locationData = null;
                                    });
                                  }
                                  : _getCurrentLocation,
                        ),

                        // Photo button
                        IconButton(
                          icon: Icon(
                            Icons.photo_camera,
                            color:
                                _imageFile != null
                                    ? AppTheme.primaryColor
                                    : AppTheme.lightGrey,
                            size: 20,
                          ),
                          onPressed: _showImageSourceDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                _isSubmitting
                    ? SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        strokeWidth: 2,
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color:
                            _commentController.text.trim().isEmpty &&
                                    _imageFile == null
                                ? AppTheme.mediumGrey
                                : AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          size: 18,
                          color:
                              _commentController.text.trim().isEmpty &&
                                      _imageFile == null
                                  ? AppTheme.lightGrey
                                  : AppTheme.whiteColor,
                        ),
                        onPressed:
                            _commentController.text.trim().isEmpty &&
                                    _imageFile == null
                                ? null
                                : _submitComment,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();

    // Allow empty content if there's an image
    if (content.isEmpty && _imageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please add a comment or image'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // First upload image if exists
      String? commentImageUrl;
      if (_imageFile != null) {
        commentImageUrl = await _uploadImage(_imageFile!);
        if (commentImageUrl == null && content.isEmpty) {
          // If image upload failed and no content, don't proceed
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      // Get location string if available
      String? locationString;
      if (_locationData != null) {
        locationString =
            '${_locationData!.latitude!.toStringAsFixed(4)}, ${_locationData!.longitude!.toStringAsFixed(4)}';
      }

      // Add comment with image url and location if available
      await ref
          .read(commentsProvider(widget.song.id!).notifier)
          .addComment(
            content.isEmpty ? null : content,
            commentImageUrl: commentImageUrl,
            location: locationString,
          );

      if (mounted) {
        setState(() {
          _commentController.clear();
          _imageFile = null;
          _locationData = null;
        });

        // Scroll to bottom after adding comment
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error submitting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to post comment'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      // Get current timestamp for unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      // Create a unique filename
      final filename = 'comment_image_${userId}_$timestamp.jpg';
      final path = '$userId/$filename';

      // Upload to comment_images bucket
      await Supabase.instance.client.storage
          .from('comment_images')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('comment_images')
          .getPublicUrl(path);

      debugPrint('Comment image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading comment image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _toggleLike(String commentId) async {
    try {
      await ref
          .read(commentsProvider(widget.song.id!).notifier)
          .toggleLike(commentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to like comment'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showCommentOptions(String commentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Delete option
                  ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.errorColor),
                    title: Text(
                      'Delete Comment',
                      style: TextStyle(color: AppTheme.whiteColor),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteComment(commentId);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: AppTheme.darkGrey,
                  ),
                  const SizedBox(height: 10),

                  // Cancel option
                  ListTile(
                    leading: Icon(Icons.close, color: AppTheme.lightGrey),
                    title: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.whiteColor),
                    ),
                    onTap: () => Navigator.pop(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: AppTheme.darkGrey,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _confirmDeleteComment(String commentId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkGrey,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_forever,
                  color: AppTheme.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Comment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whiteColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete this comment?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.lightGrey),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.whiteColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: AppTheme.whiteColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            await ref
                                .read(
                                  commentsProvider(widget.song.id!).notifier,
                                )
                                .deleteComment(commentId);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Comment deleted'),
                                  backgroundColor: AppTheme.darkGrey,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Failed to delete comment',
                                  ),
                                  backgroundColor: AppTheme.errorColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

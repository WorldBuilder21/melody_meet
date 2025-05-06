import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/auth/schemas/account.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Account user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  File? _imageFile;
  bool _isLoading = false;
  bool _usernameExists = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.whiteColor,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? AppTheme.lightGrey : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile picture
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.darkGrey,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child:
                          _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                              : widget.user.image_url != null
                              ? CachedNetworkImage(
                                imageUrl: widget.user.image_url!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.lightGrey,
                                    ),
                              )
                              : Icon(
                                Icons.person,
                                size: 60,
                                color: AppTheme.lightGrey,
                              ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.backgroundColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Username field
            TextField(
              controller: _usernameController,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: AppTheme.lightGrey),
                filled: true,
                fillColor: AppTheme.darkGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppTheme.lightGrey,
                ),
                errorText: _usernameError,
                errorStyle: TextStyle(color: AppTheme.errorColor),
              ),
              onChanged: (value) async {
                // Clear error if user is typing
                if (_usernameError != null) {
                  setState(() {
                    _usernameError = null;
                  });
                }

                // Check if username exists (only if different from current)
                if (value != widget.user.username) {
                  await _checkUsernameAvailability(value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Email field (read-only)
            TextField(
              controller: _emailController,
              style: TextStyle(color: AppTheme.whiteColor),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppTheme.lightGrey),
                filled: true,
                fillColor: AppTheme.darkGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppTheme.lightGrey,
                ),
                suffixIcon: Icon(Icons.lock_outline, color: AppTheme.lightGrey),
              ),
            ),
            const SizedBox(height: 24),

            // Bio field
            TextField(
              controller: _bioController,
              style: TextStyle(color: AppTheme.whiteColor),
              maxLines: 4,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: 'Bio',
                labelStyle: TextStyle(color: AppTheme.lightGrey),
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppTheme.darkGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.edit_note, color: AppTheme.lightGrey),
                ),
                counterStyle: TextStyle(color: AppTheme.lightGrey),
              ),
            ),
            const SizedBox(height: 32),

            // Save button (for mobile-friendly access)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.whiteColor,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          'Save Changes',
                          style: TextStyle(
                            color: AppTheme.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.darkGrey,
            title: Text(
              'Select Image Source',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    'Gallery',
                    style: TextStyle(color: AppTheme.whiteColor),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                  title: Text(
                    'Camera',
                    style: TextStyle(color: AppTheme.whiteColor),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) return;

    final authRepo = ref.read(authRepositoryProvider);

    try {
      final exists = await authRepo.checkUsernameExists(username: username);

      setState(() {
        _usernameExists = exists;
        if (exists) {
          _usernameError = 'Username already taken';
        }
      });
    } catch (e) {
      // Silently handle errors to not interrupt user typing
      debugPrint('Error checking username: $e');
    }
  }

  Future<void> _saveProfile() async {
    // Validate inputs
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _usernameError = 'Username cannot be empty';
      });
      return;
    }

    if (_usernameExists) {
      setState(() {
        _usernameError = 'Username already taken';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);

      // Upload image if selected
      if (_imageFile != null) {
        await authRepo.uploadImage(file: _imageFile!);
      }

      // Get current user
      final currentUser = await authRepo.getAccount(widget.user.id!);

      // Update profile data
      final updatedUser = currentUser.copyWith(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // Update in database
      await ref.read(authRepositoryProvider).updateAccount(updatedUser);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Return to previous screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

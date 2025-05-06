import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/auth/widget/username_strength_checker.dart';
import 'package:melody_meets/config/theme.dart';

class UsernameScreen extends ConsumerStatefulWidget {
  final TextEditingController usernameController;
  final GlobalKey<FormState> formKey;

  const UsernameScreen({
    required this.usernameController,
    required this.formKey,
    super.key,
  });

  @override
  ConsumerState createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen>
    with SingleTickerProviderStateMixin {
  bool _isCheckingUsername = false;
  String? _usernameError;
  bool _isUsernameStrong = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start the animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) return;

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final exists = await authRepo.checkUsernameExists(username: username);

      if (exists) {
        setState(() {
          _usernameError = 'This username is already taken';
        });
      }
    } catch (e) {
      // Silently handle error
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isCheckingUsername = false;
      });
    }
  }

  void _onUsernameStrengthChanged(bool isStrong) {
    setState(() {
      _isUsernameStrong = isStrong;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: widget.formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title and subtitle with better typography
                  Text(
                    'Create your username',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a username for your account. This will be visible to others on CampusConn.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.whiteColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username field with improved styling
                  TextFormField(
                    controller: widget.usernameController,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    cursorColor: AppTheme.primaryColor,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter a username',
                      errorText: _usernameError,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: _buildSuffixIcon(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return 'Username can only contain letters, numbers, and underscores';
                      }
                      if (_usernameError != null) {
                        return _usernameError;
                      }
                      if (!_isUsernameStrong) {
                        return 'Username does not meet all requirements';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Clear previous error
                      setState(() {
                        _usernameError = null;
                      });

                      // Only check username if it's valid
                      if (value.length >= 3 &&
                          RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        _checkUsername(value);
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // Username requirements card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Username Requirements:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Username strength checker - always display it
                        UsernameStrengthChecker(
                          username: widget.usernameController.text,
                          onStrengthChanged: _onUsernameStrengthChanged,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Username tips
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.tips_and_updates,
                              color: AppTheme.accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tips for a good username:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.whiteColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Keep it simple and memorable'),
                        _buildTip('Avoid personal information like birth year'),
                        _buildTip(
                          'Choose something that reflects you or your interests',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (_isCheckingUsername) {
      return Container(
        margin: const EdgeInsets.all(14),
        width: 20,
        height: 20,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryColor,
        ),
      );
    } else if (widget.usernameController.text.isNotEmpty) {
      if (_isUsernameStrong && _usernameError == null) {
        return const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 24,
        );
      } else if (_usernameError != null) {
        return const Icon(Icons.error, color: AppTheme.errorColor, size: 24);
      }
    }
    // Return an empty widget instead of null
    return const SizedBox.shrink();
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.mediumGrey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.whiteColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

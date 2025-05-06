import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/config/theme.dart';

class EmailScreen extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;

  const EmailScreen({
    required this.emailController,
    required this.formKey,
    super.key,
  });

  @override
  ConsumerState createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen>
    with SingleTickerProviderStateMixin {
  bool _isCheckingEmail = false;
  String? _emailError;
  bool _acceptedTerms = false;

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

  Future<void> _checkEmail(String email) async {
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final exists = await authRepo.checkEmailExists(email: email);

      if (exists) {
        setState(() {
          _emailError = 'This email is already in use';
        });
      }
    } catch (e) {
      // Silently handle error
    } finally {
      setState(() {
        _isCheckingEmail = false;
      });
    }
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
                  // Email icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.alternate_email,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title and subtitle
                  Text(
                    'What\'s your email?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the email you\'d like to use with your CampusConn account.',
                    style: TextStyle(color: AppTheme.whiteColor, height: 1.5),
                    // style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    //   color: AppTheme.mediumGrey,
                    //   height: 1.5,
                    // ),
                  ),
                  const SizedBox(height: 32),

                  // Email field with improved styling
                  TextFormField(
                    controller: widget.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    cursorColor: AppTheme.primaryColor,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      errorText: _emailError,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon:
                          _isCheckingEmail
                              ? Container(
                                margin: const EdgeInsets.all(14),
                                width: 20,
                                height: 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                              : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      if (_emailError != null) {
                        return _emailError;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Clear previous error
                      setState(() {
                        _emailError = null;
                      });

                      // Only check email if it's valid
                      if (RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                        _checkEmail(value);
                      }
                    },
                  ),

                  const SizedBox(height: 40),

                  // Email tips with card styling
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
                          'Email Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEmailTip(
                          'Use this email to log in to your account',
                        ),
                        _buildEmailTip(
                          'Make sure you have access to this email',
                        ),
                        _buildEmailTip(
                          'We recommend using your school email address',
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

  Widget _buildEmailTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
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

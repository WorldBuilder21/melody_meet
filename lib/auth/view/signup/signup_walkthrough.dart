import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/auth/view/login/login_field.dart';
import 'package:melody_meets/auth/view/signup/email_screen.dart';
import 'package:melody_meets/auth/view/signup/password_screen.dart';
import 'package:melody_meets/auth/view/signup/username_screen.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Form keys for each page
List<GlobalKey<FormState>> formKeys = [
  GlobalKey<FormState>(), // Username Screen
  GlobalKey<FormState>(), // Password Screen
  GlobalKey<FormState>(), // Email Screen
];

class SignupWalkthrough extends ConsumerStatefulWidget {
  static const routeName = '/signup_walkthrough';
  const SignupWalkthrough({super.key});

  @override
  ConsumerState<SignupWalkthrough> createState() => _SignupWalkthroughState();
}

class _SignupWalkthroughState extends ConsumerState<SignupWalkthrough>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Page controller
  final pageController = PageController(initialPage: 0);

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool isLoading = false;
  int currentIndex = 0;
  bool _successAnimation = false;

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

    // Start the animations
    _animationController.forward();
  }

  @override
  void dispose() {
    pageController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Get screens with dynamic titles based on current step
  List<Widget> getScreens() {
    return [
      UsernameScreen(
        usernameController: _usernameController,
        formKey: formKeys[0],
      ),
      PasswordScreen(
        password: _passwordController,
        confirmpassword: _confirmPasswordController,
        formkey: formKeys[1],
      ),
      EmailScreen(emailController: _emailController, formKey: formKeys[2]),
    ];
  }

  void _moveToNextScreen() {
    setState(() => currentIndex += 1);
    pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _moveToPreviousScreen() {
    if (currentIndex > 0) {
      setState(() => currentIndex -= 1);
      pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleUsernameStep() async {
    final formState = formKeys[0].currentState;
    if (formState == null || !formState.validate()) return;
    formState.save();

    setState(() => isLoading = true);
    try {
      // Check if username exists
      final usernameExists = await ref
          .read(authRepositoryProvider)
          .checkUsernameExists(username: _usernameController.text.trim());

      if (usernameExists) {
        if (mounted) {
          context.showAlert('Username already taken', AppTheme.errorColor);
        }
        setState(() => isLoading = false);
        return;
      }

      _moveToNextScreen();
      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        context.showAlert('An error occurred', AppTheme.errorColor);
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordStep() async {
    final formState = formKeys[1].currentState;
    if (formState == null || !formState.validate()) return;
    formState.save();

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        context.showAlert('Passwords do not match', AppTheme.errorColor);
      }
      return;
    }

    _moveToNextScreen();
  }

  Future<void> _handleSignUp() async {
    final formState = formKeys[2].currentState;
    if (formState == null || !formState.validate()) return;
    formState.save();

    setState(() => isLoading = true);
    try {
      // Check if email exists
      final emailExists = await ref
          .read(authRepositoryProvider)
          .checkEmailExists(email: _emailController.text.trim());

      if (emailExists) {
        if (mounted) {
          context.showAlert('Email already registered', AppTheme.errorColor);
          setState(() => isLoading = false);
        }
        return;
      }

      // Create account
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signupWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Add user to database
      await authRepo.addUserToDatabase(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
      );

      if (mounted) {
        // Show success animation
        setState(() {
          _successAnimation = true;
          isLoading = false;
        });

        // Wait for animation to complete
        await Future.delayed(const Duration(milliseconds: 1500));

        if (!mounted) return;

        // Navigate to login screen
        Navigator.pushReplacementNamed(context, LoginField.routeName);

        // Show success message
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Account created successfully! You can now login.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        context.showAlert(e.toString(), AppTheme.errorColor);
        setState(() => isLoading = false);
      }
    }
  }

  String _getStepTitle() {
    switch (currentIndex) {
      case 0:
        return 'Step 1 of 3: Create Username';
      case 1:
        return 'Step 2 of 3: Set Password';
      case 2:
        return 'Step 3 of 3: Add Email';
      default:
        return 'Create Account';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = getScreens();
    final isLastStep = currentIndex == screens.length - 1;
    final isFirstStep = currentIndex == 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.whiteColor,
            size: 22,
          ),
          onPressed: () {
            if (isFirstStep) {
              Navigator.pop(context);
            } else {
              _moveToPreviousScreen();
            }
          },
          splashRadius: 24,
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            _getStepTitle(),
            style: const TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (isFirstStep) {
            return true;
          } else {
            _moveToPreviousScreen();
            return false;
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Page indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SmoothPageIndicator(
                    controller: pageController,
                    count: screens.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppTheme.primaryColor,
                      dotColor: Colors.grey[300]!,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                ),

                // Main content
                Expanded(
                  child:
                      _successAnimation
                          ? _buildSuccessAnimation()
                          : PageView(
                            onPageChanged:
                                (index) => setState(() => currentIndex = index),
                            physics: const NeverScrollableScrollPhysics(),
                            controller: pageController,
                            children: screens,
                          ),
                ),

                // Navigation controls
                if (!_successAnimation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button (conditionally shown)
                        if (!isFirstStep)
                          OutlinedButton.icon(
                            onPressed: _moveToPreviousScreen,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 120), // Spacer for alignment
                        // Next/Submit button with gradient
                        Container(
                          width: 160,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      switch (currentIndex) {
                                        case 0:
                                          await _handleUsernameStep();
                                          break;
                                        case 1:
                                          await _handlePasswordStep();
                                          break;
                                        case 2:
                                          await _handleSignUp();
                                          break;
                                      }
                                    },
                            child:
                                isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isLastStep ? 'Sign Up' : 'Next',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isLastStep
                                              ? Icons.check
                                              : Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon with animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.successColor,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Account Created!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your account has been created successfully. Redirecting to login...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Loading indicator
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }
}

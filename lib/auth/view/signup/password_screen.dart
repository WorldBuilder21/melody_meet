import 'package:flutter/material.dart';
import 'package:melody_meets/auth/widget/password_strength_checker.dart';
import 'package:melody_meets/config/theme.dart';

class PasswordScreen extends StatefulWidget {
  final TextEditingController password;
  final TextEditingController confirmpassword;
  final Key formkey;
  const PasswordScreen({
    super.key,
    required this.password,
    required this.confirmpassword,
    required this.formkey,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen>
    with SingleTickerProviderStateMixin {
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isStrong = false;
  bool _obscureText = true;
  bool _confirmObscureText = true;

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
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Form(
              key: widget.formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Password icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title and subtitle with better typography
                  Text(
                    'Create your password',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your password must be at least 8 characters long, and contain at least one letter, one digit and one special character.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.whiteColor,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Password fields with improved styling
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildConfirmPasswordField(),

                  const SizedBox(height: 30),

                  // Password strength section
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
                          'Password Strength:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: widget.password,
                          builder: (context, child) {
                            final password = widget.password.text;

                            return PasswordStrengthChecker(
                              onStrengthChanged: (bool value) {
                                setState(() {
                                  _isStrong = value;
                                });
                              },
                              password: password,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password tips
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
                              'Tips for a strong password:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.whiteColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Use a mix of letters, numbers, and symbols'),
                        _buildTip('Avoid using personal information'),
                        _buildTip(
                          'Don\'t use the same password for multiple accounts',
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

  Widget _buildPasswordField() {
    return TextFormField(
      maxLines: 1,
      focusNode: _passwordFocusNode,
      controller: widget.password,
      obscureText: _obscureText,
      textInputAction: TextInputAction.next,
      cursorColor: AppTheme.primaryColor,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          splashRadius: 20,
        ),
      ),
      validator: (String? value) {
        RegExp regExp = RegExp(
          r"^(?=.*[A-Z])(?=.*[!@#\$%^&*(),.?:{}|<>])(?=.*\d).{8,}$",
        );
        if (value == null || value.isEmpty) {
          return "Please enter a password";
        } else if (!regExp.hasMatch(value)) {
          return "Password must contain at least 8 characters, including uppercase, special character, and number";
        }
        return null;
      },
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(_confirmFocusNode);
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      maxLines: 1,
      focusNode: _confirmFocusNode,
      controller: widget.confirmpassword,
      obscureText: _confirmObscureText,
      textInputAction: TextInputAction.done,
      cursorColor: AppTheme.primaryColor,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Confirm your password',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _confirmObscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _confirmObscureText = !_confirmObscureText;
            });
          },
          splashRadius: 20,
        ),
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return "Please confirm your password";
        } else if (widget.password.text != value) {
          return "Passwords do not match";
        }
        return null;
      },
      onChanged: (String value) {
        setState(() {
          widget.confirmpassword.text = value;
        });
      },
    );
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

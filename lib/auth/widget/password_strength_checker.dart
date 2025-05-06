import 'package:melody_meets/config/theme.dart';
import 'package:flutter/material.dart';

class PasswordStrengthChecker extends StatefulWidget {
  const PasswordStrengthChecker({
    super.key,
    required this.password,
    required this.onStrengthChanged,
  });

  /// Password value: obtained from a text field
  final String password;

  /// Callback that will be called when password strength changes
  final Function(bool isStrong) onStrengthChanged;

  @override
  State<PasswordStrengthChecker> createState() =>
      _PasswordStrengthCheckerState();
}

class _PasswordStrengthCheckerState extends State<PasswordStrengthChecker> {
  @override
  void didUpdateWidget(covariant PasswordStrengthChecker oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Check if the password value has changed
    if (widget.password != oldWidget.password) {
      /// If changed, re-validate the password strength
      final isStrong = _validators.entries.every(
        (entry) => entry.key.hasMatch(widget.password),
      );

      /// Call callback with new value to notify parent widget
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onStrengthChanged(isStrong),
      );
    }
  }

  final Map<RegExp, String> _validators = {
    RegExp(r'[A-Z]'): 'Has at least one uppercase letter',
    RegExp(r'[!@#\$%^&*(),.?":{}|<>]'): 'Has at least one special character',
    RegExp(r'\d'): 'Has at least one digit',
    RegExp(r'^.{8,}$'): 'Has at least 8 characters',
  };

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.password.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _validators.entries.map((entry) {
            final hasMatch = entry.key.hasMatch(widget.password);
            final color =
                hasValue
                    ? (hasMatch ? AppTheme.successColor : Colors.red)
                    : Colors.grey;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  // Animated icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          hasValue
                              ? (hasMatch
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1))
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child:
                          hasValue
                              ? (hasMatch
                                  ? const Icon(
                                    Icons.check,
                                    color: AppTheme.successColor,
                                    size: 16,
                                  )
                                  : const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 16,
                                  ))
                              : Icon(
                                Icons.remove,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight:
                            hasMatch ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

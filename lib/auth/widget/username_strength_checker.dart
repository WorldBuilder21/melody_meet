import 'package:melody_meets/config/theme.dart';
import 'package:flutter/material.dart';

class UsernameStrengthChecker extends StatefulWidget {
  const UsernameStrengthChecker({
    super.key,
    required this.username,
    required this.onStrengthChanged,
  });

  /// Username value: obtained from a text field
  final String username;

  /// Callback that will be called when username strength changes
  final Function(bool isStrong) onStrengthChanged;

  @override
  State<UsernameStrengthChecker> createState() =>
      _UsernameStrengthCheckerState();
}

class _UsernameStrengthCheckerState extends State<UsernameStrengthChecker> {
  @override
  void didUpdateWidget(covariant UsernameStrengthChecker oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Check if the username value has changed
    if (widget.username != oldWidget.username) {
      /// If changed, re-validate the username strength
      final isStrong = _validators.entries.every(
        (entry) => entry.key.hasMatch(widget.username),
      );

      /// Call callback with new value to notify parent widget
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onStrengthChanged(isStrong),
      );
    }
  }

  final Map<RegExp, String> _validators = {
    RegExp(r'^[a-zA-Z0-9_]+$'):
        'Contains only letters, numbers, and underscores',
    RegExp(r'^.{3,20}$'): 'Between 3-20 characters',
    RegExp(r'^(?!.*[_]{2})'): 'No consecutive underscores',
    RegExp(r'^[a-zA-Z]'): 'Starts with a letter',
  };

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.username.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _validators.entries.map((entry) {
            final hasMatch = hasValue && entry.key.hasMatch(widget.username);
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

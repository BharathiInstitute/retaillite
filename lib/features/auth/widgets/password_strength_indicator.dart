/// Password strength indicator widget
/// Shows a visual bar (weak/medium/strong) below the password field
library;

import 'package:flutter/material.dart';
import 'package:retaillite/core/design/design_system.dart';

/// Visual password strength indicator
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculateStrength(password);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength bar
          Row(
            children: [
              _buildBar(strength >= 1, strength.color),
              const SizedBox(width: 4),
              _buildBar(strength >= 2, strength.color),
              const SizedBox(width: 4),
              _buildBar(strength >= 3, strength.color),
              const SizedBox(width: 4),
              _buildBar(strength >= 4, strength.color),
            ],
          ),
          const SizedBox(height: 4),
          // Label + hint
          Row(
            children: [
              Text(
                strength.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strength.color,
                ),
              ),
              const SizedBox(width: 8),
              if (strength.hint.isNotEmpty)
                Expanded(
                  child: Text(
                    strength.hint,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(bool active, Color color) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: active ? color : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  static _PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) return _PasswordStrength.none;

    int score = 0;

    // Length checks
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Map score to strength level
    if (score <= 2) {
      return _PasswordStrength.weak;
    } else if (score <= 4) {
      return _PasswordStrength.fair;
    } else if (score <= 5) {
      return _PasswordStrength.good;
    } else {
      return _PasswordStrength.strong;
    }
  }
}

enum _PasswordStrength {
  none(0, 'Too short', Colors.grey, 'Enter at least 6 characters'),
  weak(1, 'Weak', Colors.red, 'Add numbers or special characters'),
  fair(2, 'Fair', Colors.orange, 'Add uppercase & special characters'),
  good(3, 'Good', Colors.blue, 'Almost there!'),
  strong(4, 'Strong', Colors.green, '');

  final int level;
  final String label;
  final Color color;
  final String hint;

  const _PasswordStrength(this.level, this.label, this.color, this.hint);

  bool operator >=(int other) => level >= other;
}

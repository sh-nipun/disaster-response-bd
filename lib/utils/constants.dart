import 'package:flutter/material.dart';

/// App er sob color ekhane define kora
class AppColors {
  static const Color primary = Color(0xFFD32F2F);   // Deep Red
  static const Color secondary = Color(0xFF1565C0); // Deep Blue
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color warning = Color(0xFFF57F17);   // Amber
  static const Color success = Color(0xFF2E7D32);   // Green
  static const Color error = Color(0xFFC62828);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

/// App er sob text style ekhane
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}

/// App er sob string constant
class AppStrings {
  static const String appName = 'DisasterAid BD';
  static const String sosTitle = 'SOS - Emergency Help!';
  static const String noInternet = 'Internet connection নেই';
}

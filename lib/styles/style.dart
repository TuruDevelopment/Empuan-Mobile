import 'package:flutter/material.dart';

class AppColors {
  /// Burgundy brand colour: primary buttons, active tab, links.
  static const primary = Color(0xFF6A1E3A);

  /// Deep plum: pressed states and text on blush surfaces.
  static const primaryVariant = Color(0xFF4B0E28);

  /// Muted coral mauve: progress, decorative accents.
  static const secondary = Color(0xFFB95B76);

  /// Soft coral: decorative only, never text.
  static const highlight = Color(0xFFE58A97);

  static const background = Color(0xFFF9F6F6);
  static const surface = Color(0xFFFFFFFF);

  /// Avatar fill.
  static const surfaceAlt = Color(0xFFEBD1D1);

  /// Light tint for selected rows, tonal buttons and notes.
  static const blush = Color(0xFFF5E8EB);

  static const textPrimary = Color(0xFF2F2F2F);

  /// Darker than the original #7D7D7D so small text passes 4.5:1.
  static const textSecondary = Color(0xFF6E6E6E);

  /// Borders and outlines for error states.
  static const error = Color(0xFFD6455D);

  /// Fill for SOS and destructive buttons; white text passes 4.5:1 on it.
  static const danger = Color(0xFFB8304A);

  /// Tint behind danger icons.
  static const dangerTint = Color(0xFFFBE7EA);

  static const accent = Color(0xFFE6B7C3);

  /// Card borders and dividers.
  static const line = Color(0xFFEFE3E6);

  /// Input borders and unselected controls.
  static const line2 = Color(0xFFE2CDD3);

  /// Chevrons and other quiet icons.
  static const quietIcon = Color(0xFFB9A9AE);
}

class AppFonts {
  static const body = 'Plus Jakarta Sans';

  /// Only for the "Empuan" wordmark.
  static const wordmark = 'Brodies';
}

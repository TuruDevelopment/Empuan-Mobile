import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'style.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      headlineLarge: TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontSize: 17, height: 23 / 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleSmall: TextStyle(fontSize: 15, height: 21 / 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, height: 26 / 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 15, height: 22 / 15, color: AppColors.textPrimary),
      bodySmall: TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      labelSmall: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppColors.textSecondary),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line2, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.body,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.blush,
        onPrimaryContainer: AppColors.primaryVariant,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.line2,
        outlineVariant: AppColors.line,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(backgroundColor: AppColors.background),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: AppFonts.body, color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE7DFE1),
          disabledForegroundColor: const Color(0xFF8E8487),
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 2)),
        hintStyle: const TextStyle(color: Color(0xFF8A8285), fontSize: 15),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
        helperStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line2),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.blush,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(fontFamily: AppFonts.body, color: Colors.white, fontSize: 14),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.line2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFFD8CDD0),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.white,
        ),
        side: const BorderSide(color: AppColors.line2, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.line2,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}

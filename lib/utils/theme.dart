import 'package:material_ui/material_ui.dart';

/// All colors used in the app, taken from the Figma design.
/// Change a color here and every screen updates.
class AppColors {
  static const cream = Color(0xFFF5F9E8);
  static const paleGreen = Color(0xFFE4EFD3);
  static const lightGreen = Color(0xFFC5DFA8);
  static const green = Color(0xFF2E6B34);
  static const deepGreen = Color(0xFF2A5D31);
  static const orange = Color(0xFFEBA95E);
  static const alertBg = Color(0xFFF9D9D6);
  static const alertText = Color(0xFFB3261E);
  static const textDark = Color(0xFF1F3A24);
  static const textMuted = Color(0xFF6B7F6E);
}

/// The app-wide theme. Buttons are green, pill-shaped and full width by default.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      surface: AppColors.cream,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 3,
      ),
    ),
  );
}
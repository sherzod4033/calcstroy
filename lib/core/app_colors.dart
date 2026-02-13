import 'dart:ui';

import '../services/app_settings_controller.dart';

class AppColors {
  AppColors._();

  static Brightness get _brightness => AppSettingsController.instance
      .resolveBrightness(PlatformDispatcher.instance.platformBrightness);

  static bool get _isDark => _brightness == Brightness.dark;

  // Primary
  static const Color primary = Color(0xFFF2780D);
  static const Color primaryLight = Color(0xFFFFF0E5);
  static const Color _primaryContainerLight = Color(0xFFFFDBCA);
  static const Color _primaryContainerDark = Color(0xFF52321D);
  static const Color _onPrimaryContainerLight = Color(0xFF331200);
  static const Color _onPrimaryContainerDark = Color(0xFFFFE7DB);

  static Color get primaryContainer =>
      _isDark ? _primaryContainerDark : _primaryContainerLight;
  static Color get onPrimaryContainer =>
      _isDark ? _onPrimaryContainerDark : _onPrimaryContainerLight;

  // Background
  static const Color _backgroundLight = Color(0xFFF8F7F5);
  static const Color backgroundDark = Color(0xFF221810);

  static Color get background => _isDark ? backgroundDark : _backgroundLight;

  // Surface
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2F241C);
  static const Color _surfaceVariantLight = Color(0xFFF0EDEA);
  static const Color surfaceVariantDark = Color(0xFF3D2F25);

  static Color get surface => _isDark ? surfaceDark : _surfaceLight;
  static Color get surfaceVariant =>
      _isDark ? surfaceVariantDark : _surfaceVariantLight;

  // Secondary background (was hardcoded 0xFFFAFAFA / 0xFFE9E9E9 / 0xFFF5F5F5)
  static const Color _secondaryBgLight = Color(0xFFFAFAFA);
  static const Color _secondaryBgDark = Color(0xFF382B22);

  static Color get secondaryBackground =>
      _isDark ? _secondaryBgDark : _secondaryBgLight;

  // Text
  static const Color _textPrimaryLight = Color(0xFF1A1A1A);
  static const Color _textPrimaryDark = Color(0xFFF5F0EA);
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFFC6B8AE);
  static const Color _textHintLight = Color(0xFF9E9E9E);
  static const Color _textHintDark = Color(0xFFA59387);
  static const Color _onSurfaceVariantLight = Color(0xFF52443C);
  static const Color _onSurfaceVariantDark = Color(0xFFD2C3B8);

  static Color get textPrimary =>
      _isDark ? _textPrimaryDark : _textPrimaryLight;
  static Color get textSecondary =>
      _isDark ? _textSecondaryDark : _textSecondaryLight;
  static Color get textHint => _isDark ? _textHintDark : _textHintLight;
  static Color get onSurfaceVariant =>
      _isDark ? _onSurfaceVariantDark : _onSurfaceVariantLight;

  // Borders / Outlines
  static const Color _outlineLight = Color(0xFFE0E0E0);
  static const Color outlineDark = Color(0xFF85736B);

  static Color get outline => _isDark ? outlineDark : _outlineLight;

  // Category icon backgrounds
  static const Color _categoryRedLight = Color(0xFFFEF2F2);
  static const Color _categoryRedDark = Color(0xFF4A2020);
  static const Color _categoryPurpleLight = Color(0xFFFAF5FF);
  static const Color _categoryPurpleDark = Color(0xFF3A2050);
  static const Color _categoryTealLight = Color(0xFFF0FDFA);
  static const Color _categoryTealDark = Color(0xFF1A3A34);
  static const Color _categoryYellowLight = Color(0xFFFFFBEB);
  static const Color _categoryYellowDark = Color(0xFF3D3418);
  static const Color _categoryPinkLight = Color(0xFFFDF2F8);
  static const Color _categoryPinkDark = Color(0xFF452038);
  static const Color _categoryBlueLight = Color(0xFFEFF6FF);
  static const Color _categoryBlueDark = Color(0xFF1E2A3D);

  static Color get categoryRed =>
      _isDark ? _categoryRedDark : _categoryRedLight;
  static Color get categoryPurple =>
      _isDark ? _categoryPurpleDark : _categoryPurpleLight;
  static Color get categoryTeal =>
      _isDark ? _categoryTealDark : _categoryTealLight;
  static Color get categoryYellow =>
      _isDark ? _categoryYellowDark : _categoryYellowLight;
  static Color get categoryPink =>
      _isDark ? _categoryPinkDark : _categoryPinkLight;
  static Color get categoryBlue =>
      _isDark ? _categoryBlueDark : _categoryBlueLight;

  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

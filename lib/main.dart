import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'services/app_settings_controller.dart';
import 'screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsController.instance.load();
  runApp(const BuildCalcApp());
}

class BuildCalcApp extends StatelessWidget {
  const BuildCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        _updateSystemUi(settings);
        return MaterialApp(
          title: 'BuildCalc',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const MainNavigation(),
        );
      },
    );
  }

  void _updateSystemUi(AppSettingsController settings) {
    final brightness = settings.resolveBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? const Color(0xFF221810)
            : const Color(0xFFF8F7F5),
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}

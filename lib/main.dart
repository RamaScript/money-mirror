import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/theme_mananger.dart';

import 'app_routes.dart';
import 'database/database_seeder.dart';

// Global theme manager instance
final themeManager = ThemeManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed database with default data on first launch
  await DatabaseSeeder.seedIfNeeded();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Mirror',
      debugShowCheckedModeBanner: false,
      // themeMode: ThemeMode.dark, // Force dark (you can make system later)
      themeMode: themeManager.themeMode,

      darkTheme: _darkTheme,
      // theme: _lightTheme, // Fallback
      // home: MainScreen(),
      theme: _lightTheme,

      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primaryColor,
    secondary: AppColors.secondryColor,
  ),
  scaffoldBackgroundColor: AppColors.darkScaffold,
  cardColor: AppColors.grey900,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkAppBar,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: AppColors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkAppBar,
    selectedItemColor: AppColors.secondryColor,
    unselectedItemColor: AppColors.grey,
    type: BottomNavigationBarType.fixed,
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: AppColors.darkAppBar),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: AppColors.primaryColor,
    contentTextStyle: TextStyle(color: AppColors.white),
  ),
  dividerColor: AppColors.grey700,
);

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.grey50,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: AppColors.white,
    iconTheme: IconThemeData(color: AppColors.black87),
    titleTextStyle: TextStyle(
      color: AppColors.black87,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardColor: AppColors.white,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.white,
    selectedItemColor: AppColors.primaryColor,
    unselectedItemColor: AppColors.grey,
    type: BottomNavigationBarType.fixed,
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: AppColors.white),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.teal700,
    contentTextStyle: const TextStyle(color: AppColors.white),
  ),
  dividerColor: AppColors.grey300,
);

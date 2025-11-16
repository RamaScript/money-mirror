import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/theme_mananger.dart';
import 'package:money_mirror/database/database_seeder.dart';

import 'app_routes.dart';

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
    primary: Colors.teal,
    secondary: Colors.tealAccent,
  ),
  scaffoldBackgroundColor: const Color(0xFF101414),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0E2222),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0E2222),
    selectedItemColor: Colors.tealAccent,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF0E2222)),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Colors.teal,
    contentTextStyle: TextStyle(color: Colors.white),
  ),
);

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black87),
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
);

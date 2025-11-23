import 'package:flutter/material.dart';

import 'views/screens/import_csv_screen.dart';
import 'views/screens/main_screen.dart';
import 'views/screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String mainScreen = '/main_screen';
  static const String importCsvScreen = '/import_csv_screen';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case importCsvScreen:
        return MaterialPageRoute(builder: (_) => const ImportCsvScreen());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}

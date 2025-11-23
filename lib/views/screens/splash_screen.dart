import 'dart:async';

import 'package:flutter/material.dart';
import 'package:money_mirror/app_routes.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for a short splash duration then decide where to go.
    Future.delayed(const Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      if (!seenOnboarding) {
        // Mark onboarding as seen so it doesn't auto-show again on next launch.
        // The user can still trigger the demo manually from the drawer.
        await prefs.setBool('seenOnboarding', true);
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.mainScreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(ImagePaths.Logo, height: 100),
              SizedBox(height: 12),
              Text("My Money", style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

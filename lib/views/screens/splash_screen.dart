import 'dart:async';

import 'package:flutter/material.dart';
import 'package:money_mirror/app_routes.dart';
import 'package:money_mirror/core/utils/image_paths.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoutes.mainScreen);
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

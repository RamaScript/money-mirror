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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String displayedText = "";
  final String fullText = "Money Mirror";
  int textIndex = 0;

  @override
  void initState() {
    super.initState();

    // --- LOGO ANIMATION ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoController.forward();

    // --- START TYPING EFFECT ---
    startTypingEffect();

    // --- NEXT SCREEN REDIRECT ---
    Future.delayed(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      if (!seenOnboarding) {
        await prefs.setBool('seenOnboarding', true);
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.mainScreen);
      }
    });
  }

  // Typing animation
  void startTypingEffect() {
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (textIndex < fullText.length) {
        setState(() {
          displayedText += fullText[textIndex];
          textIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _logoController,
          builder: (_, __) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Image.asset(ImagePaths.Logo, height: 110),
                  ),
                ),
                const SizedBox(height: 14),

                // TYPING TEXT
                Text(
                  displayedText,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: "Pacifico",
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Track Expenses',
      'subtitle': 'Record daily expenses with ease.',
      'image': 'assets/images/onboard/onboarding1.png',
    },
    {
      'title': 'Categorize Transactions',
      'subtitle': 'Organize spending using labels.',
      'image': 'assets/images/onboard/onboarding2.png',
    },
    {
      'title': 'Visualize Trends',
      'subtitle': 'Graphs that make your spending obvious.',
      'image': 'assets/images/onboard/onboarding3.png',
    },
    {
      'title': 'Import & Backup',
      'subtitle': 'Secure and portable financial history.',
      'image': 'assets/images/onboard/onboarding4.png',
    },
    {
      'title': 'Smart Insights',
      'subtitle': 'Improve spending decisions with guidance.',
      'image': 'assets/images/onboard/onboarding5.png',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToMain() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.mainScreen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(CupertinoIcons.back),
        ),
        actions: [
          TextButton(
            onPressed: _goToMain,
            child: Text(
              'Skip',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (idx) => setState(() => _current = idx),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Expanded(
                          child: Image.asset(
                            page['image']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          page['subtitle']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicator + NEXT button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _current == i ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _current == i
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_current == _pages.length - 1) {
                        _goToMain();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _current == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

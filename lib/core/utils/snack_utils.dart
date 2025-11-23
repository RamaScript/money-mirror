import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';

class SnackUtils {
  static void show(
    BuildContext context, {
    required String message,
    required Color background,
    required IconData icon, // ⬅ icon added
    int durationMs = 3000,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final controller = AnimationController(
      vsync: Navigator.of(context),
      duration: Duration(milliseconds: durationMs),
    )..forward();

    final animation = Tween<double>(begin: 1.0, end: 0.0).animate(controller);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.fixed,
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),

        content: Material(
          color: background,
          borderRadius: BorderRadius.circular(8), // full width look

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.white), // ⬅ ICON HERE
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(color: AppColors.white, fontSize: 16),
                      ),
                    ),

                    GestureDetector(
                      onTap: () =>
                          ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                      child: Icon(Icons.close, color: AppColors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: animation.value,
                      color: AppColors.white,
                      backgroundColor: background.withOpacity(0.3),
                      minHeight: 3,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        duration: Duration(milliseconds: durationMs),
      ),
    );
  }

  /// Helper Methods with Icons
  static void success(BuildContext context, String msg) => show(
    context,
    message: msg,
    background: AppColors.green600,
    icon: Icons.check_circle, // ✔ Success icon
  );

  static void error(BuildContext context, String msg) => show(
    context,
    message: msg,
    background: AppColors.red700,
    icon: Icons.error, // ❌ Error icon
  );

  static void warning(BuildContext context, String msg) => show(
    context,
    message: msg,
    background: AppColors.orange700,
    icon: Icons.warning_amber, // ⚠ Warning icon
  );

  static void info(BuildContext context, String msg) => show(
    context,
    message: msg,
    background: AppColors.blue600,
    icon: Icons.info, // ℹ Info icon
  );
}

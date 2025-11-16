import 'package:flutter/material.dart';

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
        backgroundColor: Colors.transparent,
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
                    Icon(icon, color: Colors.white), // ⬅ ICON HERE
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    GestureDetector(
                      onTap: () =>
                          ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: animation.value,
                      color: Colors.white,
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
    background: Colors.green.shade600,
    icon: Icons.check_circle, // ✔ Success icon
  );

  static void error(BuildContext context, String msg) => show(
    context,
    message: msg,
    background: Colors.red.shade700,
    icon: Icons.error, // ❌ Error icon
  );

  static void warning(BuildContext context, String msg) => show(
    context,
    message: msg,
    background: Colors.orange.shade700,
    icon: Icons.warning_amber, // ⚠ Warning icon
  );

  static void info(BuildContext context, String msg) => show(
    context,
    message: msg,
    background: Colors.blue.shade600,
    icon: Icons.info, // ℹ Info icon
  );
}

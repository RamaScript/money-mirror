import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/views/widgets/filter_dialog.dart';

class MonthSelectorWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ViewMode viewMode;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onFilterTap;
  final bool showFilterButton;

  const MonthSelectorWidget({
    super.key,
    required this.selectedDate,
    required this.viewMode,
    this.startDate,
    this.endDate,
    required this.onPrevious,
    required this.onNext,
    this.onFilterTap,
    this.showFilterButton = true,
  });

  String _getDisplayText() {
    switch (viewMode) {
      case ViewMode.daily:
        return DateFormat('MMM dd, yyyy').format(selectedDate);
      case ViewMode.weekly:
        final weekStart = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
      case ViewMode.monthly:
        return DateFormat('MMMM yyyy').format(selectedDate);
      case ViewMode.threeMonths:
        final end = DateTime(selectedDate.year, selectedDate.month + 3, 0);
        return '${DateFormat('MMM').format(selectedDate)} - ${DateFormat('MMM yyyy').format(end)}';
      case ViewMode.sixMonths:
        final end = DateTime(selectedDate.year, selectedDate.month + 6, 0);
        return '${DateFormat('MMM').format(selectedDate)} - ${DateFormat('MMM yyyy').format(end)}';
      case ViewMode.yearly:
        return DateFormat('yyyy').format(selectedDate);
      case ViewMode.custom:
        if (startDate != null && endDate != null) {
          return '${DateFormat('MMM dd').format(startDate!)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}';
        }
        return 'Custom Range';
    }
  }

  String _getSubtitleText() {
    switch (viewMode) {
      case ViewMode.daily:
        return DateFormat('EEEE').format(selectedDate);
      case ViewMode.weekly:
        return 'Week of ${DateFormat('MMM dd').format(selectedDate)}';
      case ViewMode.monthly:
        return DateFormat('EEEE').format(selectedDate);
      case ViewMode.threeMonths:
        return '3 Month Period';
      case ViewMode.sixMonths:
        return '6 Month Period';
      case ViewMode.yearly:
        return 'Year ${selectedDate.year}';
      case ViewMode.custom:
        if (startDate != null && endDate != null) {
          final days = endDate!.difference(startDate!).inDays + 1;
          return '$days days';
        }
        return 'Select date range';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
        border: Border.all(width: 0.5, color: theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          // Previous Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPrevious,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  ImagePaths.icArrowLeft,
                  color: Theme.of(context).colorScheme.primary,
                  height: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Date Display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _getDisplayText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _getSubtitleText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Next Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNext,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  ImagePaths.icArrowRight,
                  color: Theme.of(context).colorScheme.primary,
                  height: 20,
                ),
              ),
            ),
          ),

          // Filter Button
          if (showFilterButton) ...[
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    ImagePaths.icFilter,
                    color: Theme.of(context).colorScheme.primary,
                    height: 20,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

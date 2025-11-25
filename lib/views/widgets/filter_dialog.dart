import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/image_paths.dart';

enum ViewMode { daily, weekly, monthly, threeMonths, sixMonths, yearly, custom }

class FilterDialog extends StatefulWidget {
  final ViewMode? initialMode;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(ViewMode, DateTime?, DateTime?) onModeSelected;

  const FilterDialog({
    super.key,
    this.initialMode,
    this.initialStartDate,
    this.initialEndDate,
    required this.onModeSelected,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late ViewMode selectedMode;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    selectedMode = widget.initialMode ?? ViewMode.monthly;
    startDate =
        widget.initialStartDate ??
        DateTime.now().subtract(const Duration(days: 30));
    endDate = widget.initialEndDate ?? DateTime.now();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryColor,
              surface: Colors.grey.shade900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate != null && startDate!.isAfter(endDate!)) {
          endDate = startDate!.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryColor,
              surface: Colors.grey.shade900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Mode',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 24),

                  SvgPicture.asset(
                    ImagePaths.icFilter,
                    color: Theme.of(context).colorScheme.primary,
                    height: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 20),

            // View Mode Options
            ...ViewMode.values.map(
              (mode) =>
                  _buildModeOption(context, mode, selectedMode == mode, () {
                    setState(() => selectedMode = mode);
                  }),
            ),

            // Custom Date Range Pickers (shown when custom is selected)
            if (selectedMode == ViewMode.custom) ...[
              const SizedBox(height: 20),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Start Date",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    startDate != null
                                        ? DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(startDate!)
                                        : 'Select start date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "End Date",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectEndDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    endDate != null
                                        ? DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(endDate!)
                                        : 'Select end date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMode == ViewMode.custom) {
                      if (startDate != null && endDate != null) {
                        widget.onModeSelected(selectedMode, startDate, endDate);
                        Navigator.pop(context);
                      }
                    } else {
                      widget.onModeSelected(selectedMode, null, null);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context,
    ViewMode mode,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getModeIcon(mode),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getModeLabel(mode),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.daily:
        return Icons.today;
      case ViewMode.weekly:
        return Icons.view_week;
      case ViewMode.monthly:
        return Icons.calendar_month;
      case ViewMode.threeMonths:
        return Icons.calendar_view_month;
      case ViewMode.sixMonths:
        return Icons.date_range;
      case ViewMode.yearly:
        return Icons.calendar_today;
      case ViewMode.custom:
        return Icons.edit_calendar;
    }
  }

  String _getModeLabel(ViewMode mode) {
    switch (mode) {
      case ViewMode.daily:
        return 'Daily';
      case ViewMode.weekly:
        return 'Weekly';
      case ViewMode.monthly:
        return 'Monthly';
      case ViewMode.threeMonths:
        return '3 Months';
      case ViewMode.sixMonths:
        return '6 Months';
      case ViewMode.yearly:
        return 'Yearly';
      case ViewMode.custom:
        return 'Custom';
    }
  }
}

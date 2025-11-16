import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHeader extends StatelessWidget {
  final DateTime date;

  const DateHeader({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('MMM dd, EEEE').format(date),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}


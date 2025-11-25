import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';

class AnalysisOverviewTab extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, dynamic> comparison;
  final List<Map<String, dynamic>> categoryBreakdown;
  final int transactionCount;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> dailyExpenseData;
  final List<Map<String, dynamic>> dailyIncomeData;

  const AnalysisOverviewTab({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.comparison,
    required this.categoryBreakdown,
    required this.transactionCount,
    required this.startDate,
    required this.endDate,
    required this.dailyExpenseData,
    required this.dailyIncomeData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(child: buildOverviewTab(theme));
  }

  Widget buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comparison.isNotEmpty) buildComparisonCard(theme),
          const SizedBox(height: 16),
          buildInsightsCard(theme),
          // const SizedBox(height: 16),
          // buildQuickStats(theme),
          const SizedBox(height: 16),
          buildCalendarView(theme),
        ],
      ),
    );
  }

  Widget buildComparisonCard(ThemeData theme) {
    final expenseChange = comparison['expense_change'] as double;
    final expensePercentage = comparison['expense_percentage'] as double;
    final isIncrease = expenseChange > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                ImagePaths.icArrowComparison,
                color: theme.colorScheme.primary,
                height: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "Period Comparison",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Expense Change:"),
              Row(
                children: [
                  SvgPicture.asset(
                    isIncrease
                        ? ImagePaths.icArrowTrendUp
                        : ImagePaths.icArrowTrendDown,
                    color: isIncrease
                        ? AppColors.expenseColor
                        : AppColors.incomeColor,
                    height: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${expensePercentage.abs().toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: isIncrease
                          ? AppColors.expenseColor
                          : AppColors.incomeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isIncrease
                ? "You spent ${PrefCurrencySymbol.rupee}${expenseChange.toStringAsFixed(2)} more than the previous period"
                : "You saved ${PrefCurrencySymbol.rupee}${expenseChange.abs().toStringAsFixed(2)} compared to the previous period",
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInsightsCard(ThemeData theme) {
    final avgDaily = totalExpense / (endDate.difference(startDate).inDays + 1);
    final topCategory = categoryBreakdown.isNotEmpty
        ? categoryBreakdown.first
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                "Insights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const Divider(),
          buildInsightRow(
            theme,
            ImagePaths.icCalender,
            "Average daily spending",
            PrefCurrencySymbol.rupee + avgDaily.toStringAsFixed(2),
          ),
          if (topCategory != null)
            buildInsightRow(
              theme,
              ImagePaths.icArrowTrendUp,
              "Highest spending category",
              "${topCategory['category_name']} (${PrefCurrencySymbol.rupee}${(topCategory['total'] as num).toDouble().toStringAsFixed(2)})",
            ),
          buildInsightRow(
            theme,
            ImagePaths.icNote,
            "Total transactions",
            transactionCount.toString(),
          ),
          if (balance < 0)
            buildInsightRow(
              theme,
              ImagePaths.icWarning,
              "Warning",
              "Expenses exceed income",
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget buildInsightRow(
    ThemeData theme,
    String icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SvgPicture.asset(icon, color: theme.colorScheme.primary, height: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color ?? theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatItem(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          PrefCurrencySymbol.rupee + value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget buildCalendarView(ThemeData theme) {
    // Get all unique dates from both expense and income data
    final allDates = <DateTime>{};
    for (var data in dailyExpenseData) {
      try {
        final date = DateTime.parse(data['day']);
        allDates.add(DateTime(date.year, date.month, date.day));
      } catch (e) {
        appLog("⚠️ Error parsing date: ${data['day']}");
      }
    }
    for (var data in dailyIncomeData) {
      try {
        final date = DateTime.parse(data['day']);
        allDates.add(DateTime(date.year, date.month, date.day));
      } catch (e) {
        appLog("⚠️ Error parsing date: ${data['day']}");
      }
    }

    if (allDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "No transaction data available for calendar view",
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    }

    final sortedDates = allDates.toList()..sort();
    final firstDate = sortedDates.first;
    final month = firstDate.month;
    final year = firstDate.year;

    // Create a map for quick lookup
    final expenseMap = <String, double>{};
    for (var data in dailyExpenseData) {
      try {
        final date = DateTime.parse(data['day']);
        final key = '${date.year}-${date.month}-${date.day}';
        expenseMap[key] = (data['total'] as num).toDouble();
      } catch (e) {
        // Skip invalid dates
      }
    }

    final incomeMap = <String, double>{};
    for (var data in dailyIncomeData) {
      try {
        final date = DateTime.parse(data['day']);
        final key = '${date.year}-${date.month}-${date.day}';
        incomeMap[key] = (data['total'] as num).toDouble();
      } catch (e) {
        // Skip invalid dates
      }
    }

    // Get first day of month and number of days
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                ImagePaths.icCalender,
                color: theme.colorScheme.primary,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM yyyy').format(firstDayOfMonth),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          ...List.generate(((firstWeekday - 1 + daysInMonth) / 7).ceil(), (
            weekIndex,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }

                  final date = DateTime(year, month, dayNumber);
                  final key = '${date.year}-${date.month}-${date.day}';
                  final expense = expenseMap[key] ?? 0.0;
                  final income = incomeMap[key] ?? 0.0;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (expense > 0 || income > 0)
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (expense > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                expense >= 1000
                                    ? '-${PrefCurrencySymbol.rupee}${(expense / 1000).toStringAsFixed(1)}k'
                                    : '-${PrefCurrencySymbol.rupee}${expense.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.expenseColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (income > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                income >= 1000
                                    ? '+${PrefCurrencySymbol.rupee}${(income / 1000).toStringAsFixed(1)}k'
                                    : '+${PrefCurrencySymbol.rupee}${income.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.incomeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';

class AnalysisTrendsTab extends StatelessWidget {
  final List<Map<String, dynamic>> dailyExpenseData;
  final List<Map<String, dynamic>> dailyIncomeData;
  final List<Map<String, dynamic>> accountBreakdown;

  final String selectedFlowView;
  final Function(String) onFlowViewChange;

  final String selectedDailyView;
  final Function(String) onDailyViewChange;

  final String selectedAccountView;
  final Function(String) onAccountViewChange;

  const AnalysisTrendsTab({
    super.key,
    required this.dailyExpenseData,
    required this.dailyIncomeData,
    required this.accountBreakdown,
    required this.selectedFlowView,
    required this.onFlowViewChange,
    required this.selectedDailyView,
    required this.onDailyViewChange,
    required this.selectedAccountView,
    required this.onAccountViewChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return buildTrendsTab(theme);
  }

  Widget buildTrendsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Flow selector
          buildFlowSelector(theme),
          const SizedBox(height: 16),

          // Expense Flow or Income Flow based on selection
          if (selectedFlowView == 'expense')
            dailyExpenseData.isNotEmpty
                ? buildExpenseFlowChart(theme)
                : buildEmptyState(theme, "No expense flow data available")
          else
            dailyIncomeData.isNotEmpty
                ? buildIncomeFlowChart(theme)
                : buildEmptyState(theme, "No income flow data available"),

          const SizedBox(height: 24),

          // Daily selector
          buildDailySelector(theme),
          const SizedBox(height: 16),

          // Daily Expenses or Daily Income based on selection
          if (selectedDailyView == 'expense')
            dailyExpenseData.isNotEmpty
                ? buildBarChart(theme)
                : buildEmptyState(theme, "No daily expense data available")
          else
            dailyIncomeData.isNotEmpty
                ? buildDailyIncomeBarChart(theme)
                : buildEmptyState(theme, "No daily income data available"),

          const SizedBox(height: 24),

          // Calendar View
          // buildCalendarView(theme),
          // const SizedBox(height: 24),

          // Account Analysis
          if (accountBreakdown.isNotEmpty) ...[
            // buildAccountViewSelector(theme),
            // const SizedBox(height: 16),
            buildAccountAnalysisChart(theme),
            const SizedBox(height: 24),
            buildAccountAnalysisList(theme),
          ] else
            buildEmptyState(theme, "No account data available"),
        ],
      ),
    );
  }

  Widget buildFlowSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onFlowViewChange('expense'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedFlowView == 'expense'
                      ? AppColors.expenseColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Expense Flow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedFlowView == 'expense'
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onFlowViewChange('income'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedFlowView == 'income'
                      ? AppColors.incomeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Income Flow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedFlowView == 'income'
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDailySelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onDailyViewChange('expense'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedDailyView == 'expense'
                      ? AppColors.expenseColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Daily Expense',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedDailyView == 'expense'
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onDailyViewChange('income'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedDailyView == 'income'
                      ? AppColors.incomeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Daily Income',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedDailyView == 'income'
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState(
    ThemeData theme,
    String message, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 40),
      height: isCompact ? 250 : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: isCompact ? 32 : 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: isCompact ? 12 : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget buildAccountViewSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onAccountViewChange('combined'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedAccountView == 'combined'
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'All Accounts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selectedAccountView == 'combined'
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ),
          ...accountBreakdown.map((account) {
            final accountId = account['account_id'].toString();
            return Expanded(
              child: GestureDetector(
                onTap: () => onAccountViewChange(accountId),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedAccountView == accountId
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    account['account_icon'] ?? '🏦',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedAccountView == accountId
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildDailyIncomeBarChart(ThemeData theme) {
    final barGroups = dailyIncomeData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value['total'] as num).toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: AppColors.incomeColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 300,
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
          Text(
            "Daily Income",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: theme.dividerColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          PrefCurrencySymbol.rupee + value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dailyIncomeData.length) {
                          final date = DateTime.parse(
                            dailyIncomeData[value.toInt()]['day'],
                          );
                          return Text(
                            DateFormat('dd').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExpenseFlowChart(ThemeData theme) {
    final spots = dailyExpenseData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = (entry.value['total'] as num).toDouble();
      return FlSpot(index, value);
    }).toList();

    return Container(
      height: 300,
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
          Text(
            "Expense Flow",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.dividerColor,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                PrefCurrencySymbol.rupee +
                                    value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dailyExpenseData.length) {
                                final date = DateTime.parse(
                                  dailyExpenseData[value.toInt()]['day'],
                                );
                                return Text(
                                  DateFormat('dd').format(date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.expenseColor,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.expenseColor,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.expenseColor.withOpacity(0.2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.expenseColor.withOpacity(0.3),
                                AppColors.expenseColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBarChart(ThemeData theme) {
    final barGroups = dailyExpenseData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value['total'] as num).toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: AppColors.expenseColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 300,
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
          Text(
            "Daily Expenses",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: theme.dividerColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          PrefCurrencySymbol.rupee + value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dailyExpenseData.length) {
                          final date = DateTime.parse(
                            dailyExpenseData[value.toInt()]['day'],
                          );
                          return Text(
                            DateFormat('dd').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildIncomeFlowChart(ThemeData theme) {
    final spots = dailyIncomeData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = (entry.value['total'] as num).toDouble();
      return FlSpot(index, value);
    }).toList();

    return Container(
      height: 300,
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
          Text(
            "Income Flow",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.dividerColor,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                PrefCurrencySymbol.rupee +
                                    value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dailyIncomeData.length) {
                                final date = DateTime.parse(
                                  dailyIncomeData[value.toInt()]['day'],
                                );
                                return Text(
                                  DateFormat('dd').format(date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.incomeColor,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.incomeColor,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.incomeColor.withOpacity(0.2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.incomeColor.withOpacity(0.3),
                                AppColors.incomeColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAccountAnalysisChart(ThemeData theme) {
    final maxValue = accountBreakdown.fold<double>(0.0, (max, account) {
      final income = (account['income'] as num?)?.toDouble() ?? 0.0;
      final expense = (account['expense'] as num?)?.toDouble() ?? 0.0;
      return max > (income + expense) ? max : (income + expense);
    });

    final barGroups = accountBreakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final account = entry.value;
      final income = (account['income'] as num?)?.toDouble() ?? 0.0;
      final expense = (account['expense'] as num?)?.toDouble() ?? 0.0;

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: expense,
            color: AppColors.expenseColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            fromY: 0,
            toY: income,
            color: AppColors.incomeColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 300,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Account Analysis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.expenseColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Expense",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.incomeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Income",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                maxY: maxValue * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: theme.dividerColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          PrefCurrencySymbol.rupee + value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < accountBreakdown.length) {
                          final account = accountBreakdown[value.toInt()];
                          final name = account['account_name'] ?? 'Unknown';
                          return Text(
                            name.length > 6 ? name.substring(0, 6) : name,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAccountAnalysisList(ThemeData theme) {
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
          Text(
            "Account Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          ...accountBreakdown.map((account) {
            final income = (account['income'] as num?)?.toDouble() ?? 0.0;
            final expense = (account['expense'] as num?)?.toDouble() ?? 0.0;
            final icon = account['account_icon'] ?? '💰';
            final name = account['account_name'] ?? 'Unknown';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.expenseColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.expenseColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Expense: ${PrefCurrencySymbol.rupee}${expense.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.expenseColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.incomeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.incomeColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Income: ${PrefCurrencySymbol.rupee}${income.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.incomeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
          Text(
            DateFormat('MMMM, yyyy').format(firstDayOfMonth),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
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

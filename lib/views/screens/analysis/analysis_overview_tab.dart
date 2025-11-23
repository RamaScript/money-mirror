import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
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

  const AnalysisOverviewTab({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.comparison,
    required this.categoryBreakdown,
    required this.transactionCount,
    required this.startDate,
    required this.endDate,
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
          const SizedBox(height: 16),
          buildQuickStats(theme),
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
              Icon(Icons.compare_arrows, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Period Comparison",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: isIncrease
                        ? AppColors.expenseColor
                        : AppColors.incomeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${expensePercentage.abs().toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const Divider(),
          buildInsightRow(
            theme,
            Icons.calendar_today,
            "Average daily spending",
            PrefCurrencySymbol.rupee + avgDaily.toStringAsFixed(2),
          ),
          if (topCategory != null)
            buildInsightRow(
              theme,
              Icons.trending_up,
              "Highest spending category",
              "${topCategory['category_name']} (${PrefCurrencySymbol.rupee}${(topCategory['total'] as num).toDouble().toStringAsFixed(2)})",
            ),
          buildInsightRow(
            theme,
            Icons.receipt,
            "Total transactions",
            transactionCount.toString(),
          ),
          if (balance < 0)
            buildInsightRow(
              theme,
              Icons.warning,
              "Warning",
              "Expenses exceed income",
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget buildQuickStats(ThemeData theme) {
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
            "Quick Stats",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildStatItem(
                theme,
                "Income",
                totalIncome,
                AppColors.incomeColor,
              ),
              Container(width: 1, height: 40, color: theme.dividerColor),
              buildStatItem(
                theme,
                "Expense",
                totalExpense,
                AppColors.expenseColor,
              ),
              Container(width: 1, height: 40, color: theme.dividerColor),
              buildStatItem(
                theme,
                "Savings",
                balance,
                balance >= 0 ? AppColors.primaryColor : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInsightRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
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
}

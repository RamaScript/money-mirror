import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';

class AnalysisCategoryTab extends StatelessWidget {
  final String selectedCategoryType;
  final Function(String) onCategoryTypeChange;

  final List<Map<String, dynamic>> expenseBreakdown;
  final List<Map<String, dynamic>> incomeBreakdown;

  const AnalysisCategoryTab({
    super.key,
    required this.selectedCategoryType,
    required this.onCategoryTypeChange,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return buildCategoriesTab(theme);
  }

  Widget buildCategoriesTab(ThemeData theme) {
    final currentBreakdown = selectedCategoryType == 'EXPENSE'
        ? expenseBreakdown
        : incomeBreakdown;

    final total = currentBreakdown.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as num).toDouble(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Type selector
          buildCategoryTypeSelector(theme),
          const SizedBox(height: 16),

          if (currentBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 68.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(ImagePaths.icPieChart, height: 78),
                    const SizedBox(height: 16),
                    Text(
                      "No ${selectedCategoryType.toLowerCase()} data available",
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                buildPieChart(theme, total, currentBreakdown),
                const SizedBox(height: 24),
                buildCategoryList(theme, total, currentBreakdown),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildCategoryTypeSelector(ThemeData theme) {
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
              onTap: () => onCategoryTypeChange('EXPENSE'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedCategoryType == 'EXPENSE'
                      ? AppColors.expenseColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Expense',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedCategoryType == 'EXPENSE'
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onCategoryTypeChange('INCOME'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedCategoryType == 'INCOME'
                      ? AppColors.incomeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Income',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedCategoryType == 'INCOME'
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

  Widget buildPieChart(
    ThemeData theme,
    double total,
    List<Map<String, dynamic>> breakdown,
  ) {
    final colors = [
      AppColors.expenseColor,
      AppColors.primaryColor,
      AppColors.incomeColor,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    final sections = breakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = (data['total'] as num).toDouble();
      final color = colors[index % colors.length];
      final percentage = (value / total) * 100;

      return PieChartSectionData(
        value: value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: color,
        radius: 100,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
          ],
        ),
      );
    }).toList();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${selectedCategoryType == 'EXPENSE' ? 'Expense' : 'Income'} Distribution",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (selectedCategoryType == 'EXPENSE'
                              ? AppColors.expenseColor
                              : AppColors.incomeColor)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${PrefCurrencySymbol.rupee}${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selectedCategoryType == 'EXPENSE'
                        ? AppColors.expenseColor
                        : AppColors.incomeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;

              if (isSmallScreen) {
                // Stack vertically on small screens
                return Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value,
                            child: SizedBox(
                              height: 300,
                              child: PieChart(
                                PieChartData(
                                  sections: sections,
                                  centerSpaceRadius: 20,
                                  sectionsSpace: 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              } else {
                // Side by side on larger screens
                return SizedBox(
                  height: 300,
                  child: Row(
                    children: [
                      // Pie Chart
                      Expanded(
                        flex: 2,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: value,
                                child: PieChart(
                                  PieChartData(
                                    sections: sections,
                                    centerSpaceRadius: 50,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Legend
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: breakdown.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final color = colors[index % colors.length];
                              final value = (data['total'] as num).toDouble();
                              final percentage = (value / total) * 100;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.cardColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      data['category_icon'] ?? '💰',
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['category_name'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "${PrefCurrencySymbol.rupee}${value.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.color,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  "${percentage.toStringAsFixed(1)}%",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: color,
                                                    fontWeight: FontWeight.w700,
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
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildCategoryList(
    ThemeData theme,
    double total,
    List<Map<String, dynamic>> breakdown,
  ) {
    final colors = [
      AppColors.expenseColor,
      AppColors.primaryColor,
      AppColors.incomeColor,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Category Breakdown",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Text(
                "Total: ${PrefCurrencySymbol.rupee}${total.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const Divider(),
          ...breakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final amount = (data['total'] as num).toDouble();
            final percentage = (amount / total) * 100;
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['category_icon'] ?? '💰',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['category_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 6,
                            backgroundColor: theme.dividerColor,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        PrefCurrencySymbol.rupee + amount.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      Text(
                        "${percentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

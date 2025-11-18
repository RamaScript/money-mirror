import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/analysis_utils.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/views/widgets/filter_dialog.dart';
import 'package:money_mirror/views/widgets/month_selector_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Period selection
  ViewMode viewMode = ViewMode.monthly;
  DateTime selectedDate = DateTime.now();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  DateTime? customStartDate;
  DateTime? customEndDate;

  // Data
  bool isLoading = true;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double balance = 0.0;
  List<Map<String, dynamic>> categoryBreakdown = [];
  List<Map<String, dynamic>> incomeCategoryBreakdown = [];
  List<Map<String, dynamic>> dailyData = [];
  List<Map<String, dynamic>> dailyIncomeData = [];
  List<Map<String, dynamic>> accountBreakdown = [];
  Map<String, dynamic> comparison = {};
  int transactionCount = 0;

  // Category tab selection
  String selectedCategoryType = 'EXPENSE'; // 'EXPENSE' or 'INCOME'

  // Trends tab selection
  String selectedFlowView = 'expense'; // 'expense' or 'income'
  String selectedDailyView = 'expense'; // 'expense' or 'income'
  String selectedAccountView = 'combined'; // 'combined' or account ID

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    appLog("📊 [AnalysisScreen] initState() called");
    _tabController = TabController(length: 3, vsync: this);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
    _updateDateRange();
    appLog("📊 [AnalysisScreen] Calling _loadData() from initState");
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    if (viewMode == ViewMode.custom &&
        customStartDate != null &&
        customEndDate != null) {
      startDate = customStartDate!;
      endDate = customEndDate!;
      return;
    }

    final now = DateTime.now();
    final selected = selectedDate;

    switch (viewMode) {
      case ViewMode.daily:
        startDate = DateTime(selected.year, selected.month, selected.day);
        endDate = DateTime(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
          59,
        );
        // Cap end date to today
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
      case ViewMode.weekly:
        // Go back 7 days from selected date
        startDate = selected.subtract(const Duration(days: 6));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = DateTime(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
          59,
        );
        // Cap end date to today
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
      case ViewMode.monthly:
        startDate = DateTime(selected.year, selected.month, 1);
        endDate = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
        // Cap end date to today
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
      case ViewMode.threeMonths:
        // Go back 3 months from selected date
        int targetYear = selected.year;
        int targetMonth = selected.month - 3;
        if (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }
        startDate = DateTime(targetYear, targetMonth, 1);
        endDate = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
        // Cap end date to today
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
      case ViewMode.sixMonths:
        // Go back 6 months from selected date
        int targetYear6 = selected.year;
        int targetMonth6 = selected.month - 6;
        if (targetMonth6 <= 0) {
          targetMonth6 += 12;
          targetYear6 -= 1;
        }
        startDate = DateTime(targetYear6, targetMonth6, 1);
        endDate = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
        // Cap end date to today - never show future dates
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
      case ViewMode.yearly:
        // Show from start of year to selected date
        startDate = DateTime(selected.year, 1, 1);
        endDate = DateTime(selected.year, 12, 31, 23, 59, 59);
        // Cap end date to today
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
      case ViewMode.custom:
        // Fallback to current month if custom dates not set
        startDate = DateTime(selected.year, selected.month, 1);
        endDate = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
        // Cap end date to today
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
    }
  }

  Future<void> _loadData() async {
    appLog("📊 [AnalysisScreen] _loadData() called");
    setState(() => isLoading = true);
    _updateDateRange();
    appLog(
      "📊 [AnalysisScreen] Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}",
    );
    appLog("📊 [AnalysisScreen] ViewMode: $viewMode");

    appLog("📊 [AnalysisScreen] Fetching income...");
    final income = await AnalysisUtils.getTotalIncome(
      startDate: startDate,
      endDate: endDate,
    );
    appLog("📊 [AnalysisScreen] Total income: $income");

    appLog("📊 [AnalysisScreen] Fetching expense...");
    final expense = await AnalysisUtils.getTotalExpense(
      startDate: startDate,
      endDate: endDate,
    );
    appLog("📊 [AnalysisScreen] Total expense: $expense");

    appLog("📊 [AnalysisScreen] Fetching category breakdown...");
    final catBreakdown = await AnalysisUtils.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      type: 'EXPENSE',
    );
    appLog(
      "📊 [AnalysisScreen] Category breakdown: ${catBreakdown.length} categories",
    );

    final incomeCatBreakdown = await AnalysisUtils.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      type: 'INCOME',
    );
    appLog(
      "📊 [AnalysisScreen] Income category breakdown: ${incomeCatBreakdown.length} categories",
    );

    appLog("📊 [AnalysisScreen] Fetching daily expense transactions...");
    final daily = await AnalysisUtils.getDailyTransactions(
      startDate: startDate,
      endDate: endDate,
      type: 'EXPENSE',
    );
    appLog("📊 [AnalysisScreen] Daily expense data: ${daily.length} days");

    appLog("📊 [AnalysisScreen] Fetching daily income transactions...");
    final dailyIncome = await AnalysisUtils.getDailyIncome(
      startDate: startDate,
      endDate: endDate,
    );
    appLog("📊 [AnalysisScreen] Daily income data: ${dailyIncome.length} days");

    appLog("📊 [AnalysisScreen] Fetching account breakdown...");
    final accountData = await AnalysisUtils.getAccountBreakdown(
      startDate: startDate,
      endDate: endDate,
    );
    appLog(
      "📊 [AnalysisScreen] Account breakdown: ${accountData.length} accounts",
    );

    final duration = endDate.difference(startDate);
    final prevStartDate = startDate.subtract(duration);
    final prevEndDate = startDate.subtract(const Duration(seconds: 1));

    final comp = await AnalysisUtils.comparePeriods(
      period1Start: startDate,
      period1End: endDate,
      period2Start: prevStartDate,
      period2End: prevEndDate,
    );

    final counts = await AnalysisUtils.getTransactionCounts(
      startDate: startDate,
      endDate: endDate,
    );

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      balance = income - expense;
      categoryBreakdown = catBreakdown;
      incomeCategoryBreakdown = incomeCatBreakdown;
      dailyData = daily;
      dailyIncomeData = dailyIncome;
      accountBreakdown = accountData;
      comparison = comp;
      transactionCount = counts['income']! + counts['expense']!;
      isLoading = false;
    });

    appLog(
      "📊 [AnalysisScreen] Data loaded - Income: $income, Expense: $expense, Balance: $balance",
    );
    appLog("📊 [AnalysisScreen] Transaction count: $transactionCount");
  }

  void _onPrevious() {
    setState(() {
      switch (viewMode) {
        case ViewMode.daily:
          selectedDate = selectedDate.subtract(const Duration(days: 1));
          break;
        case ViewMode.weekly:
          selectedDate = selectedDate.subtract(const Duration(days: 7));
          break;
        case ViewMode.monthly:
          selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
          break;
        case ViewMode.threeMonths:
          selectedDate = DateTime(selectedDate.year, selectedDate.month - 3, 1);
          break;
        case ViewMode.sixMonths:
          selectedDate = DateTime(selectedDate.year, selectedDate.month - 6, 1);
          break;
        case ViewMode.yearly:
          selectedDate = DateTime(selectedDate.year - 1, selectedDate.month, 1);
          break;
        case ViewMode.custom:
          if (customStartDate != null && customEndDate != null) {
            final duration = customEndDate!.difference(customStartDate!);
            customStartDate = customStartDate!.subtract(duration);
            customEndDate = customEndDate!.subtract(duration);
          }
          break;
      }
    });
    _loadData();
  }

  void _onNext() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      switch (viewMode) {
        case ViewMode.daily:
          final nextDate = selectedDate.add(const Duration(days: 1));
          final nextDateOnly = DateTime(
            nextDate.year,
            nextDate.month,
            nextDate.day,
          );
          // Only allow if next date is today or in the past
          if (nextDateOnly.isBefore(today) ||
              nextDateOnly.isAtSameMomentAs(today)) {
            selectedDate = nextDate;
          }
          break;
        case ViewMode.weekly:
          final nextDate = selectedDate.add(const Duration(days: 7));
          final nextDateOnly = DateTime(
            nextDate.year,
            nextDate.month,
            nextDate.day,
          );
          // Only allow if next date is today or in the past
          if (nextDateOnly.isBefore(today) ||
              nextDateOnly.isAtSameMomentAs(today)) {
            selectedDate = nextDate;
          }
          break;
        case ViewMode.monthly:
          final nextDate = DateTime(
            selectedDate.year,
            selectedDate.month + 1,
            1,
          );
          // Only allow if next month is current month or in the past
          if (nextDate.isBefore(now) ||
              (nextDate.year == now.year && nextDate.month == now.month)) {
            selectedDate = nextDate;
          }
          break;
        case ViewMode.threeMonths:
          final nextDate = DateTime(
            selectedDate.year,
            selectedDate.month + 3,
            1,
          );
          // Only allow if next period is current month or in the past
          if (nextDate.isBefore(now) ||
              (nextDate.year == now.year && nextDate.month == now.month)) {
            selectedDate = nextDate;
          }
          break;
        case ViewMode.sixMonths:
          final nextDate = DateTime(
            selectedDate.year,
            selectedDate.month + 6,
            1,
          );
          // Only allow if next period is current month or in the past
          if (nextDate.isBefore(now) ||
              (nextDate.year == now.year && nextDate.month == now.month)) {
            selectedDate = nextDate;
          }
          break;
        case ViewMode.yearly:
          final nextDate = DateTime(
            selectedDate.year + 1,
            selectedDate.month,
            1,
          );
          // Only allow if next year is current year or in the past
          if (nextDate.isBefore(now) || (nextDate.year == now.year)) {
            selectedDate = nextDate;
          }
          break;
        case ViewMode.custom:
          if (customStartDate != null && customEndDate != null) {
            final duration = customEndDate!.difference(customStartDate!);
            final nextStart = customStartDate!.add(duration);
            final nextEnd = customEndDate!.add(duration);
            // Only allow if next period end is today or in the past
            if (nextEnd.isBefore(now) || nextEnd.isAtSameMomentAs(now)) {
              customStartDate = nextStart;
              customEndDate = nextEnd;
            }
          }
          break;
      }
    });
    _loadData();
  }

  void _onFilterTap() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        initialMode: viewMode,
        initialStartDate: customStartDate,
        initialEndDate: customEndDate,
        onModeSelected: (mode, startDate, endDate) {
          setState(() {
            viewMode = mode;
            if (mode == ViewMode.custom) {
              customStartDate = startDate;
              customEndDate = endDate;
            } else {
              customStartDate = null;
              customEndDate = null;
              // Reset selectedDate to today when changing filter mode
              // This ensures we show the most recent period by default
              final now = DateTime.now();
              selectedDate = DateTime(now.year, now.month, now.day);
            }
          });
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analysis"),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Categories"),
            Tab(text: "Trends"),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Column(
              children: [
                // Month Selector
                MonthSelectorWidget(
                  selectedDate: selectedDate,
                  viewMode: viewMode,
                  startDate: customStartDate,
                  endDate: customEndDate,
                  onPrevious: _onPrevious,
                  onNext: _onNext,
                  onFilterTap: _onFilterTap,
                  showFilterButton: true,
                ),

                const SizedBox(height: 8),

                // Summary Cards
                _buildSummaryCards(theme),

                // Tab Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primaryColor,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(theme),
                        _buildCategoriesTab(theme),
                        _buildTrendsTab(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              theme,
              "EXPENSE",
              totalExpense,
              AppColors.expenseColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              theme,
              "INCOME",
              totalIncome,
              AppColors.incomeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              theme,
              "TOTAL",
              balance,
              balance >= 0 ? AppColors.primaryColor : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String label,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${amount >= 0 ? '' : '-'}${PrefCurrencySymbol.rupee}${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comparison.isNotEmpty) _buildComparisonCard(theme),
          const SizedBox(height: 16),
          _buildInsightsCard(theme),
          const SizedBox(height: 16),
          _buildQuickStats(theme),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(ThemeData theme) {
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

  Widget _buildInsightsCard(ThemeData theme) {
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
          _buildInsightRow(
            theme,
            Icons.calendar_today,
            "Average daily spending",
            PrefCurrencySymbol.rupee + avgDaily.toStringAsFixed(2),
          ),
          if (topCategory != null)
            _buildInsightRow(
              theme,
              Icons.trending_up,
              "Highest spending category",
              "${topCategory['category_name']} (${PrefCurrencySymbol.rupee}${(topCategory['total'] as num).toDouble().toStringAsFixed(2)})",
            ),
          _buildInsightRow(
            theme,
            Icons.receipt,
            "Total transactions",
            transactionCount.toString(),
          ),
          if (balance < 0)
            _buildInsightRow(
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

  Widget _buildInsightRow(
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

  Widget _buildQuickStats(ThemeData theme) {
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
              _buildStatItem(
                theme,
                "Income",
                totalIncome,
                AppColors.incomeColor,
              ),
              Container(width: 1, height: 40, color: theme.dividerColor),
              _buildStatItem(
                theme,
                "Expense",
                totalExpense,
                AppColors.expenseColor,
              ),
              Container(width: 1, height: 40, color: theme.dividerColor),
              _buildStatItem(
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

  Widget _buildStatItem(
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

  Widget _buildCategoriesTab(ThemeData theme) {
    final currentBreakdown = selectedCategoryType == 'EXPENSE'
        ? categoryBreakdown
        : incomeCategoryBreakdown;

    if (currentBreakdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              "No ${selectedCategoryType.toLowerCase()} data available",
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
      );
    }

    final total = currentBreakdown.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as num).toDouble(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Type selector
          _buildCategoryTypeSelector(theme),
          const SizedBox(height: 16),
          _buildPieChart(theme, total, currentBreakdown),
          const SizedBox(height: 24),
          _buildCategoryList(theme, total, currentBreakdown),
        ],
      ),
    );
  }

  Widget _buildCategoryTypeSelector(ThemeData theme) {
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
              onTap: () => setState(() => selectedCategoryType = 'EXPENSE'),
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
              onTap: () => setState(() => selectedCategoryType = 'INCOME'),
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

  Widget _buildPieChart(
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
        title: percentage > 0 ? '${percentage.toStringAsFixed(0)}%' : '',
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
        badgeWidget: percentage <= 100
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  data['category_icon'] ?? '💰',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
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
                    // SizedBox(
                    //   height: 300,
                    //   child: SingleChildScrollView(
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: breakdown.asMap().entries.map((entry) {
                    //         final index = entry.key;
                    //         final data = entry.value;
                    //         final color = colors[index % colors.length];
                    //         final value = (data['total'] as num).toDouble();
                    //         final percentage = (value / total) * 100;
                    //
                    //         return Container(
                    //           margin: const EdgeInsets.only(bottom: 12),
                    //           padding: const EdgeInsets.all(12),
                    //           decoration: BoxDecoration(
                    //             color: theme.cardColor.withOpacity(0.5),
                    //             borderRadius: BorderRadius.circular(12),
                    //             border: Border.all(
                    //               color: color.withOpacity(0.3),
                    //               width: 1,
                    //             ),
                    //           ),
                    //           child: Row(
                    //             children: [
                    //               Text(
                    //                 data['category_icon'] ?? '💰',
                    //                 style: const TextStyle(fontSize: 20),
                    //               ),
                    //               const SizedBox(width: 12),
                    //               Expanded(
                    //                 child: Column(
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.start,
                    //                   children: [
                    //                     Text(
                    //                       data['category_name'] ?? 'Unknown',
                    //                       style: TextStyle(
                    //                         fontSize: 14,
                    //                         fontWeight: FontWeight.w600,
                    //                         color: theme
                    //                             .textTheme
                    //                             .bodyLarge
                    //                             ?.color,
                    //                       ),
                    //                       maxLines: 1,
                    //                       overflow: TextOverflow.ellipsis,
                    //                     ),
                    //                     const SizedBox(height: 4),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           "${PrefCurrencySymbol.rupee}${value.toStringAsFixed(2)}",
                    //                           style: TextStyle(
                    //                             fontSize: 13,
                    //                             fontWeight: FontWeight.bold,
                    //                             color: theme
                    //                                 .textTheme
                    //                                 .titleLarge
                    //                                 ?.color,
                    //                           ),
                    //                         ),
                    //                         Text(
                    //                           "${percentage.toStringAsFixed(1)}%",
                    //                           style: TextStyle(
                    //                             fontSize: 12,
                    //                             color: color,
                    //                             fontWeight: FontWeight.w600,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         );
                    //       }).toList(),
                    //     ),
                    //   ),
                    // ),
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

  Widget _buildCategoryList(
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

  Widget _buildTrendsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Flow selector
          _buildFlowSelector(theme),
          const SizedBox(height: 16),

          // Expense Flow or Income Flow based on selection
          if (selectedFlowView == 'expense')
            dailyData.isNotEmpty
                ? _buildExpenseFlowChart(theme)
                : _buildEmptyState(theme, "No expense flow data available")
          else
            dailyIncomeData.isNotEmpty
                ? _buildIncomeFlowChart(theme)
                : _buildEmptyState(theme, "No income flow data available"),

          const SizedBox(height: 24),

          // Daily selector
          _buildDailySelector(theme),
          const SizedBox(height: 16),

          // Daily Expenses or Daily Income based on selection
          if (selectedDailyView == 'expense')
            dailyData.isNotEmpty
                ? _buildBarChart(theme)
                : _buildEmptyState(theme, "No daily expense data available")
          else
            dailyIncomeData.isNotEmpty
                ? _buildDailyIncomeBarChart(theme)
                : _buildEmptyState(theme, "No daily income data available"),

          const SizedBox(height: 24),

          // Calendar View
          _buildCalendarView(theme),

          const SizedBox(height: 24),

          // Account Analysis
          if (accountBreakdown.isNotEmpty) ...[
            _buildAccountViewSelector(theme),
            const SizedBox(height: 16),
            _buildAccountAnalysisChart(theme),
            const SizedBox(height: 24),
            _buildAccountAnalysisList(theme),
          ] else
            _buildEmptyState(theme, "No account data available"),
        ],
      ),
    );
  }

  Widget _buildFlowSelector(ThemeData theme) {
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
              onTap: () => setState(() => selectedFlowView = 'expense'),
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
              onTap: () => setState(() => selectedFlowView = 'income'),
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

  Widget _buildDailySelector(ThemeData theme) {
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
              onTap: () => setState(() => selectedDailyView = 'expense'),
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
              onTap: () => setState(() => selectedDailyView = 'income'),
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

  Widget _buildEmptyState(
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

  Widget _buildAccountViewSelector(ThemeData theme) {
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
              onTap: () => setState(() => selectedAccountView = 'combined'),
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
                onTap: () => setState(() => selectedAccountView = accountId),
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

  Widget _buildDailyIncomeBarChart(ThemeData theme) {
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

  Widget _buildExpenseFlowChart(ThemeData theme) {
    final spots = dailyData.asMap().entries.map((entry) {
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
                                  value.toInt() < dailyData.length) {
                                final date = DateTime.parse(
                                  dailyData[value.toInt()]['day'],
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

  Widget _buildBarChart(ThemeData theme) {
    final barGroups = dailyData.asMap().entries.map((entry) {
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
                            value.toInt() < dailyData.length) {
                          final date = DateTime.parse(
                            dailyData[value.toInt()]['day'],
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

  Widget _buildIncomeFlowChart(ThemeData theme) {
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

  Widget _buildAccountAnalysisChart(ThemeData theme) {
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

  Widget _buildAccountAnalysisList(ThemeData theme) {
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

  Widget _buildCalendarView(ThemeData theme) {
    // Get all unique dates from both expense and income data
    final allDates = <DateTime>{};
    for (var data in dailyData) {
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
    final lastDate = sortedDates.last;
    final month = firstDate.month;
    final year = firstDate.year;

    // Create a map for quick lookup
    final expenseMap = <String, double>{};
    for (var data in dailyData) {
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

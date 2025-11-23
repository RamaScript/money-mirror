import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/views/screens/analysis/analysis_categories_tab.dart';
import 'package:money_mirror/views/screens/analysis/analysis_trends_tab.dart';
import 'package:money_mirror/views/screens/analysis/analysis_utils.dart';
import 'package:money_mirror/views/widgets/filter_dialog.dart';
import 'package:money_mirror/views/widgets/month_selector_widget.dart';

import 'analysis_overview_tab.dart';

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.TertiaryColor, // background uses theme
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              dividerColor: Colors.transparent,

              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withOpacity(0.65),

              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),

              indicatorSize: TabBarIndicatorSize.tab,
              overlayColor: WidgetStateProperty.all(Colors.transparent),

              indicator: BoxDecoration(
                color: AppColors.white.withOpacity(
                  0.18,
                ), // subtle theme highlight
                borderRadius: BorderRadius.circular(12),
              ),

              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Categories"),
                Tab(text: "Trends"),
              ],
            ),
          ),
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
                        AnalysisOverviewTab(
                          totalIncome: totalIncome,
                          totalExpense: totalExpense,
                          balance: balance,
                          comparison: comparison,
                          categoryBreakdown: categoryBreakdown,
                          transactionCount: transactionCount,
                          startDate: startDate,
                          endDate: endDate,
                          dailyExpenseData: dailyData,
                          dailyIncomeData: dailyIncomeData,
                        ),

                        AnalysisCategoryTab(
                          selectedCategoryType: selectedCategoryType,
                          onCategoryTypeChange: (value) =>
                              setState(() => selectedCategoryType = value),
                          expenseBreakdown: categoryBreakdown,
                          incomeBreakdown: incomeCategoryBreakdown,
                        ),

                        AnalysisTrendsTab(
                          dailyExpenseData: dailyData,
                          dailyIncomeData: dailyIncomeData,
                          accountBreakdown: accountBreakdown,

                          selectedFlowView: selectedFlowView,
                          onFlowViewChange: (v) =>
                              setState(() => selectedFlowView = v),

                          selectedDailyView: selectedDailyView,
                          onDailyViewChange: (v) =>
                              setState(() => selectedDailyView = v),

                          selectedAccountView: selectedAccountView,
                          onAccountViewChange: (v) =>
                              setState(() => selectedAccountView = v),
                        ),
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
}

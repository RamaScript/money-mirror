import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/transaction_dao.dart';
import 'package:money_mirror/views/screens/add_transaction_screen.dart';
import 'package:money_mirror/views/widgets/date_header.dart';
import 'package:money_mirror/views/widgets/filter_dialog.dart';
import 'package:money_mirror/views/widgets/month_selector_widget.dart';
import 'package:money_mirror/views/widgets/transaction_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> transactions = [];
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double balance = 0.0;
  bool isLoading = true;

  DateTime selectedDate = DateTime.now();
  ViewMode viewMode = ViewMode.monthly;
  DateTime? customStartDate;
  DateTime? customEndDate;

  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    appLog("🏠 [HomeScreen] initState() called");
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _updateDateRange();
    appLog("🏠 [HomeScreen] Calling loadData() from initState");
    loadData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    if (viewMode == ViewMode.custom &&
        customStartDate != null &&
        customEndDate != null) {
      _startDate = customStartDate!;
      _endDate = customEndDate!;
      return;
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (viewMode) {
      case ViewMode.daily:
        startDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        endDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
        // Cap end date to today only if selected date is today or in the past
        final selectedDateOnly = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        final todayOnly = DateTime(now.year, now.month, now.day);
        if (selectedDateOnly.isBefore(todayOnly) ||
            selectedDateOnly.isAtSameMomentAs(todayOnly)) {
          if (endDate.isAfter(now)) {
            endDate = now;
          }
        }
        break;
      case ViewMode.weekly:
        // Go back 7 days from selected date
        startDate = selectedDate.subtract(const Duration(days: 6));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
        // Cap end date to today only if selected date is today or in the past
        final selectedDateOnly = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        final todayOnly = DateTime(now.year, now.month, now.day);
        if (selectedDateOnly.isBefore(todayOnly) ||
            selectedDateOnly.isAtSameMomentAs(todayOnly)) {
          if (endDate.isAfter(now)) {
            endDate = now;
          }
        }
        break;
      case ViewMode.monthly:
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          0,
          23,
          59,
          59,
        );
        // Cap end date to today only if selected month is current month or in the past
        final selectedMonth = DateTime(
          selectedDate.year,
          selectedDate.month,
          1,
        );
        final currentMonth = DateTime(now.year, now.month, 1);
        if (selectedMonth.isBefore(currentMonth) ||
            selectedMonth.isAtSameMomentAs(currentMonth)) {
          if (endDate.isAfter(now)) {
            endDate = now;
          }
        }
        break;
      case ViewMode.threeMonths:
        // Go back 3 months from selected date (including selected month)
        // If selected is November, show September, October, November
        int targetYear = selectedDate.year;
        int targetMonth =
            selectedDate.month - 2; // -2 because we include current month
        if (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }
        startDate = DateTime(targetYear, targetMonth, 1);
        endDate = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          0,
          23,
          59,
          59,
        );
        // Cap end date to today only if selected period includes current month
        final selectedMonth = DateTime(
          selectedDate.year,
          selectedDate.month,
          1,
        );
        final currentMonth = DateTime(now.year, now.month, 1);
        if (selectedMonth.isBefore(currentMonth) ||
            selectedMonth.isAtSameMomentAs(currentMonth)) {
          if (endDate.isAfter(now)) {
            endDate = now;
          }
        }
        break;
      case ViewMode.sixMonths:
        // Go back 6 months from selected date
        int targetYear6 = selectedDate.year;
        int targetMonth6 = selectedDate.month - 6;
        if (targetMonth6 <= 0) {
          targetMonth6 += 12;
          targetYear6 -= 1;
        }
        startDate = DateTime(targetYear6, targetMonth6, 1);
        endDate = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          0,
          23,
          59,
          59,
        );
        // Cap end date to today only if selected period includes current month
        final selectedMonth6 = DateTime(
          selectedDate.year,
          selectedDate.month,
          1,
        );
        final currentMonth6 = DateTime(now.year, now.month, 1);
        if (selectedMonth6.isBefore(currentMonth6) ||
            selectedMonth6.isAtSameMomentAs(currentMonth6)) {
          if (endDate.isAfter(now)) {
            endDate = now;
          }
        }
        break;
      case ViewMode.yearly:
        // Show from start of year to selected date
        startDate = DateTime(selectedDate.year, 1, 1);
        endDate = DateTime(selectedDate.year, 12, 31, 23, 59, 59);
        // Cap end date to today only if selected year is current year or in the past
        if (selectedDate.year <= now.year) {
          if (endDate.isAfter(now)) {
            endDate = now;
          }
        }
        break;
      case ViewMode.custom:
        // Fallback to current month if custom dates not set
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          0,
          23,
          59,
          59,
        );
        // Cap end date to today
        if (endDate.isAfter(now)) {
          endDate = now;
        }
        break;
    }

    _startDate = startDate;
    _endDate = endDate;
  }

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  Future<void> loadData() async {
    appLog("🏠 [HomeScreen] loadData() called");
    setState(() => isLoading = true);
    _updateDateRange();

    appLog(
      "🏠 [HomeScreen] Date range: ${_startDate.toIso8601String()} to ${_endDate.toIso8601String()}",
    );
    appLog("🏠 [HomeScreen] ViewMode: $viewMode");
    appLog("🏠 [HomeScreen] SelectedDate: ${selectedDate.toIso8601String()}");

    try {
      // Debug: Check all transactions first
      final allTransactions = await TransactionDao.getAllTransactions();
      appLog(
        "🏠 [HomeScreen] DEBUG: Total transactions in DB: ${allTransactions.length}",
      );
      if (allTransactions.isNotEmpty) {
        final firstDate = DateTime.parse(allTransactions.first['date']);
        final lastDate = DateTime.parse(allTransactions.last['date']);
        appLog(
          "🏠 [HomeScreen] DEBUG: Transaction date range in DB: ${firstDate.toIso8601String()} to ${lastDate.toIso8601String()}",
        );
      }

      appLog("🏠 [HomeScreen] Fetching transactions...");
      final transactionData = await TransactionDao.getTransactionsByDateRange(
        startDate: _startDate,
        endDate: _endDate,
      );
      appLog(
        "🏠 [HomeScreen] Transactions fetched: ${transactionData.length} transactions",
      );
      if (transactionData.isEmpty) {
        appLog("⚠️ [HomeScreen] WARNING: No transactions found in date range!");
        appLog("⚠️ [HomeScreen] Try changing the view mode or date range");
      }

      appLog("🏠 [HomeScreen] Fetching income...");
      final income = await TransactionDao.getTotalIncomeByDateRange(
        startDate: _startDate,
        endDate: _endDate,
      );
      appLog("🏠 [HomeScreen] Total income: $income");

      appLog("🏠 [HomeScreen] Fetching expense...");
      final expense = await TransactionDao.getTotalExpenseByDateRange(
        startDate: _startDate,
        endDate: _endDate,
      );
      appLog("🏠 [HomeScreen] Total expense: $expense");

      setState(() {
        transactions = transactionData;
        totalIncome = income;
        totalExpense = expense;
        balance = income - expense;
        isLoading = false;
      });

      appLog(
        "🏠 [HomeScreen] State updated - Transactions: ${transactions.length}, Balance: $balance",
      );
    } catch (e, stackTrace) {
      appLog("❌ [HomeScreen] Error loading data: $e");
      appLog("❌ [HomeScreen] Stack trace: $stackTrace");
      setState(() {
        isLoading = false;
      });
    }
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
          // For custom, navigate by the range duration
          if (customStartDate != null && customEndDate != null) {
            final duration = customEndDate!.difference(customStartDate!);
            customStartDate = customStartDate!.subtract(duration);
            customEndDate = customEndDate!.subtract(duration);
          }
          break;
      }
    });
    loadData();
  }

  void _onNext() {
    setState(() {
      switch (viewMode) {
        case ViewMode.daily:
          selectedDate = selectedDate.add(const Duration(days: 1));
          break;
        case ViewMode.weekly:
          selectedDate = selectedDate.add(const Duration(days: 7));
          break;
        case ViewMode.monthly:
          selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
          break;
        case ViewMode.threeMonths:
          selectedDate = DateTime(selectedDate.year, selectedDate.month + 3, 1);
          break;
        case ViewMode.sixMonths:
          selectedDate = DateTime(selectedDate.year, selectedDate.month + 6, 1);
          break;
        case ViewMode.yearly:
          selectedDate = DateTime(selectedDate.year + 1, selectedDate.month, 1);
          break;
        case ViewMode.custom:
          // For custom, navigate by the range duration
          if (customStartDate != null && customEndDate != null) {
            final duration = customEndDate!.difference(customStartDate!);
            customStartDate = customStartDate!.add(duration);
            customEndDate = customEndDate!.add(duration);
          }
          break;
      }
    });
    loadData();
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
          loadData();
        },
      ),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    appLog(
      "🏠 [HomeScreen] _groupTransactionsByDate() called with ${transactions.length} transactions",
    );
    final grouped = <DateTime, List<Map<String, dynamic>>>{};

    for (var transaction in transactions) {
      try {
        final date = DateTime.parse(transaction['date']);
        final dateOnly = DateTime(date.year, date.month, date.day);

        if (!grouped.containsKey(dateOnly)) {
          grouped[dateOnly] = [];
        }
        grouped[dateOnly]!.add(transaction);
      } catch (e) {
        appLog(
          "❌ [HomeScreen] Error parsing transaction date: $e, transaction: $transaction",
        );
      }
    }

    appLog("🏠 [HomeScreen] Grouped into ${grouped.length} dates");

    // Sort dates in descending order
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final sortedGrouped = <DateTime, List<Map<String, dynamic>>>{};
    for (var date in sortedDates) {
      sortedGrouped[date] = grouped[date]!;
    }

    appLog(
      "🏠 [HomeScreen] Returning ${sortedGrouped.length} grouped date sections",
    );
    return sortedGrouped;
  }

  @override
  Widget build(BuildContext context) {
    appLog(
      "🏠 [HomeScreen] build() called - isLoading: $isLoading, transactions: ${transactions.length}",
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groupedTransactions = _groupTransactionsByDate();
    appLog(
      "🏠 [HomeScreen] Grouped transactions: ${groupedTransactions.length} date groups",
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Money Mirror",
          style: TextStyle(
            fontSize: 16,
            fontFamily: "Pacifico",
            fontWeight: FontWeight.w100,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: SvgPicture.asset(
            ImagePaths.icMenu,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              color: AppColors.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
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
                    _buildSummarySection(theme, isDark),

                    const SizedBox(height: 16),

                    // Transactions List
                    if (transactions.isEmpty)
                      _buildEmptyState(theme)
                    else
                      _buildTransactionsList(groupedTransactions, theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.tertiaryColor, AppColors.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.TOTAL_BALANCE,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            PrefCurrencySymbol.rupee + balance.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 36,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: ImagePaths.icArrowDown,
                  label: AppStrings.INCOME_LABEL,
                  amount: totalIncome,
                  color: AppColors.incomeColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  icon: ImagePaths.icArrowUp,
                  label: AppStrings.EXPENSE_LABEL,
                  amount: totalExpense,
                  color: AppColors.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(icon, color: color, height: 24),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            PrefCurrencySymbol.rupee + amount.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    Map<DateTime, List<Map<String, dynamic>>> groupedTransactions,
    ThemeData theme,
  ) {
    appLog(
      "🏠 [HomeScreen] _buildTransactionsList() called with ${groupedTransactions.length} date groups",
    );
    int totalTransactions = 0;
    for (var entry in groupedTransactions.entries) {
      totalTransactions += entry.value.length;
      appLog(
        "🏠 [HomeScreen] Date ${entry.key}: ${entry.value.length} transactions",
      );
    }
    appLog("🏠 [HomeScreen] Total transactions to display: $totalTransactions");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            AppStrings.TRANSACTIONS,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        ...groupedTransactions.entries.map((entry) {
          // appLog(
          //   "🏠 [HomeScreen] Building widget for date: ${entry.key}, transactions: ${entry.value.length}",
          // );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateHeader(date: entry.key),
              ...entry.value.map((transaction) {
                // appLog("🏠 [HomeScreen] Building TransactionCard for: ${transaction['title']}");
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TransactionCard(
                    transaction: transaction,
                    onTap: () => _showTransactionDetails(transaction),
                  ),
                );
              }),
            ],
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          SvgPicture.asset(ImagePaths.icNote, height: 64),
          const SizedBox(height: 16),
          Text(
            AppStrings.NO_TRANSACTIONS,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.ADD_FIRST_TRANSACTION,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    final theme = Theme.of(context);
    final isIncome = transaction['type'] == AppStrings.INCOME;
    final isTransfer = transaction['type'] == AppStrings.TRANSFER;
    final amount = (transaction['amount'] as num).toDouble();
    final date = DateTime.parse(transaction['date']);

    // Determine color and label based on transaction type
    Color typeColor;
    String typeLabel;
    if (isTransfer) {
      typeColor = AppColors.transferColor;
      typeLabel = AppStrings.TRANSFER_LABEL;
    } else if (isIncome) {
      typeColor = AppColors.incomeColor;
      typeLabel = AppStrings.INCOME_LABEL;
    } else {
      typeColor = AppColors.expenseColor;
      typeLabel = AppStrings.EXPENSE_LABEL;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with cross, edit, and delete buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTransactionScreen(
                                transactionToEdit: transaction,
                              ),
                            ),
                          );
                          if (result == true) {
                            loadData();
                          }
                        },
                        icon: Icon(Icons.edit, color: AppColors.primaryColor),
                        tooltip: AppStrings.EDIT,
                      ),
                      IconButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await TransactionDao.deleteTransaction(
                            transaction['id'],
                          );
                          loadData();
                          if (mounted) {
                            SnackUtils.error(context, "Transaction deleted");
                          }
                        },
                        icon: Icon(Icons.delete, color: AppColors.expenseColor),
                        tooltip: AppStrings.DELETE,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: typeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Amount
                    Text(
                      '${isIncome ? '+' : '-'}${PrefCurrencySymbol.rupee}${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: typeColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Date and Time
                    _buildDetailRow(
                      theme,
                      AppStrings.DATE,
                      DateFormat('MMM dd, yyyy').format(date),
                    ),
                    _buildDetailRow(
                      theme,
                      AppStrings.TIME,
                      DateFormat('hh:mm a').format(date),
                    ),

                    const SizedBox(height: 8),

                    // Account
                    _buildDetailRow(
                      theme,
                      AppStrings.ACCOUNT,
                      "${transaction['account_icon'] ?? '🏦'} ${transaction['account_name'] ?? 'Unknown'}",
                    ),

                    // Category
                    _buildDetailRow(
                      theme,
                      AppStrings.CATEGORY,
                      "${transaction['category_icon'] ?? '💰'} ${transaction['category_name'] ?? 'Unknown'}",
                    ),

                    // Note at bottom
                    if (transaction['note'] != null &&
                        transaction['note'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.NOTE,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transaction['note'],
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

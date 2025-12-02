import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/budget_dao.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/views/widgets/budget/create_budget_dialog.dart';
import 'package:money_mirror/views/widgets/budget/edit_budget_dialog.dart';
import 'package:money_mirror/views/widgets/budget/set_budget_dialog.dart';
import 'package:money_mirror/views/widgets/filter_dialog.dart';
import 'package:money_mirror/views/widgets/month_selector_widget.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> unbudgetedCategories = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  double totalBudget = 0.0;
  double totalSpent = 0.0;

  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    appLog("💰 [BudgetScreen] initState() called");
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    appLog("💰 [BudgetScreen] Calling _loadBudgets() from initState");
    _loadBudgets();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadBudgets() async {
    appLog("💰 [BudgetScreen] _loadBudgets() called");
    setState(() => isLoading = true);

    final month = selectedDate.month;
    final year = selectedDate.year;
    appLog("💰 [BudgetScreen] Loading budgets for month: $month, year: $year");

    try {
      appLog("💰 [BudgetScreen] Fetching budgets from database...");
      final budgetData = await BudgetDao.getBudgetsByMonthYear(
        month: month,
        year: year,
      );
      appLog("💰 [BudgetScreen] Found ${budgetData.length} budgets");

      // Debug: Print budget details
      for (var budget in budgetData) {
        appLog(
          "💰 [BudgetScreen] Budget: ${budget['category_name']} - ${budget['amount']} (ID: ${budget['id']}, Category ID: ${budget['category_id']})",
        );
      }

      // Get all expense categories
      appLog("💰 [BudgetScreen] Fetching expense categories...");
      final allCategories = await CategoryDao.getCategories(
        type: AppStrings.EXPENSE,
      );
      appLog(
        "💰 [BudgetScreen] Found ${allCategories.length} expense categories",
      );

      // Get category IDs that have budgets
      final budgetedCategoryIds = budgetData
          .map((b) => b['category_id'] as int)
          .toSet();
      appLog("💰 [BudgetScreen] Budgeted category IDs: $budgetedCategoryIds");

      // Find unbudgeted categories
      final unbudgeted = allCategories
          .where((cat) => !budgetedCategoryIds.contains(cat['id']))
          .toList();
      appLog("💰 [BudgetScreen] Unbudgeted categories: ${unbudgeted.length}");

      // Debug: Print unbudgeted category details
      for (var cat in unbudgeted) {
        appLog(
          "💰 [BudgetScreen] Unbudgeted: ${cat['name']} (ID: ${cat['id']})",
        );
      }

      double tempTotalBudget = 0.0;
      double tempTotalSpent = 0.0;

      // Load spent amounts for each budget
      appLog("💰 [BudgetScreen] Calculating spent amounts...");
      final updatedBudgets = <Map<String, dynamic>>[]; // ✅ NEW LIST

      for (var budget in budgetData) {
        try {
          final spent = await BudgetDao.getSpentAmount(
            categoryId: budget['category_id'],
            month: month,
            year: year,
            type: budget['type'],
          );

          // ✅ Create NEW mutable copy with spent value
          final mutableBudget = Map<String, dynamic>.from(budget);
          mutableBudget['spent'] = spent;
          updatedBudgets.add(mutableBudget);

          tempTotalBudget += (budget['amount'] as num).toDouble();
          tempTotalSpent += spent;

          appLog(
            "💰 [BudgetScreen] Added budget: ${budget['category_name']} with spent: $spent",
          );
        } catch (e) {
          appLog(
            "⚠️ [BudgetScreen] Error calculating spent for budget ${budget['id']}: $e",
          );

          // ✅ Create NEW mutable copy with 0 spent
          final mutableBudget = Map<String, dynamic>.from(budget);
          mutableBudget['spent'] = 0.0;
          updatedBudgets.add(mutableBudget);
        }
      }

      appLog(
        "💰 [BudgetScreen] Total budget: $tempTotalBudget, Total spent: $tempTotalSpent",
      );

      setState(() {
        budgets = updatedBudgets; // ✅ USE NEW LIST, NOT budgetData
        unbudgetedCategories = unbudgeted;
        totalBudget = tempTotalBudget;
        totalSpent = tempTotalSpent;
        isLoading = false;
      });
      appLog(
        "💰 [BudgetScreen] Total budget: $tempTotalBudget, Total spent: $tempTotalSpent",
      );

      appLog("💰 [BudgetScreen] State updated successfully");
    } catch (e, stackTrace) {
      appLog("❌ [BudgetScreen] Error loading budgets: $e");
      appLog("❌ [BudgetScreen] Stack trace: $stackTrace");
      setState(() {
        budgets = [];
        unbudgetedCategories = [];
        totalBudget = 0.0;
        totalSpent = 0.0;
        isLoading = false;
      });
    }
  }

  void _onPreviousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
    });
    _slideController.forward(from: 0.0).then((_) {
      _loadBudgets();
      _slideController.reverse();
    });
  }

  void _onNextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
    });
    _slideController.forward(from: 0.0).then((_) {
      _loadBudgets();
      _slideController.reverse();
    });
  }

  void _openCreateBudgetDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateBudgetDialog(
        onAdded: _loadBudgets,
        preSelectedMonth: selectedDate.month,
        preSelectedYear: selectedDate.year,
      ),
    );
  }

  void _openSetBudgetDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (_) => SetBudgetDialog(
        category: category,
        month: selectedDate.month,
        year: selectedDate.year,
        onBudgetSet: _loadBudgets,
      ),
    );
  }

  void _openEditBudgetDialog(Map<String, dynamic> budget) {
    showDialog(
      context: context,
      builder: (_) => EditBudgetDialog(budget: budget, onUpdated: _loadBudgets),
    );
  }

  Future<void> _deleteBudget(int id, String categoryName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Budget?"),
        content: Text(
          "Are you sure you want to delete the budget for $categoryName?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BudgetDao.deleteBudget(id);
      _loadBudgets();
      if (mounted) {
        SnackUtils.success(context, "Budget deleted successfully");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Budget",
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: SvgPicture.asset(
            ImagePaths.icMenu,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openCreateBudgetDialog,
            icon: SvgPicture.asset(
              ImagePaths.icAdd,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: "Add Budget",
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBudgets,
              color: AppColors.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Month Selector
                    MonthSelectorWidget(
                      selectedDate: selectedDate,
                      viewMode: ViewMode.monthly,
                      onPrevious: _onPreviousMonth,
                      onNext: _onNextMonth,
                      showFilterButton: false,
                    ),

                    const SizedBox(height: 8),

                    // Summary Card
                    _buildSummaryCard(theme, isDark),

                    const SizedBox(height: 16),

                    // Budgeted Categories
                    if (budgets.isNotEmpty) _buildBudgetedSection(theme),

                    // Unbudgeted Categories
                    if (unbudgetedCategories.isNotEmpty)
                      _buildUnbudgetedSection(theme),

                    // Empty State
                    if (budgets.isEmpty && unbudgetedCategories.isEmpty)
                      _buildEmptyState(theme),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark) {
    final remaining = totalBudget - totalSpent;
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
        border: Border.all(width: 0.5, color: theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOTAL BUDGET",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PrefCurrencySymbol.rupee + totalBudget.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "TOTAL SPENT",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PrefCurrencySymbol.rupee + totalSpent.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (totalBudget > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage > 100 ? 1.0 : percentage / 100,
                minHeight: 8,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 100 ? Colors.red : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Remaining: ${PrefCurrencySymbol.rupee}${remaining.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 14,
                color: remaining >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetedSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "Budgeted categories: ${DateFormat('MMM, yyyy').format(selectedDate)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        ...budgets.map((budget) => _buildBudgetCard(budget, theme)),
      ],
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic> budget, ThemeData theme) {
    appLog(
      "💰 [BudgetScreen] Building budget card for: ${budget['category_name']}",
    );
    final amount = (budget['amount'] as num).toDouble();
    final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
    final percentage = amount > 0 ? (spent / amount) * 100 : 0.0;
    final remaining = amount - spent;
    final isExceeded = spent > amount;

    appLog(
      "💰 [BudgetScreen] Amount: $amount, Spent: $spent, Percentage: ${percentage.toStringAsFixed(2)}%",
    );

    Color progressColor;
    if (percentage <= 70) {
      progressColor = Colors.green;
    } else if (percentage <= 100) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
        border: Border.all(width: 0.5, color: theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  budget['category_icon'] ?? '💰',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget['category_name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          "Limit: ${PrefCurrencySymbol.rupee}${amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Spent: ${PrefCurrencySymbol.rupee}${spent.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                color: theme.cardColor,
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditBudgetDialog(budget);
                  } else if (value == 'delete') {
                    _deleteBudget(
                      budget['id'],
                      budget['category_name'] ?? 'Unknown',
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text("Delete"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar with Limit Marker
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              // Calculate where the limit marker should be
              // If not exceeded: at 100% (right end)
              // If exceeded: at (amount/spent) * 100% position
              final limitMarkerPosition = isExceeded
                  ? barWidth * (amount / spent).clamp(0.0, 1.0)
                  : barWidth;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: isExceeded ? 1.0 : percentage / 100,
                      minHeight: 10,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  // Limit Marker (green flag)
                  Positioned(
                    left: limitMarkerPosition.clamp(0.0, barWidth - 3),
                    top: 0,
                    child: Container(
                      width: 3,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Limit amount label at marker position
                  Positioned(
                    left: (limitMarkerPosition - 25).clamp(0.0, barWidth - 50),
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${PrefCurrencySymbol.rupee}${amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Remaining: ${PrefCurrencySymbol.rupee}${remaining.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: remaining >= 0 ? Colors.green : Colors.red,
                ),
              ),
              if (isExceeded)
                Text(
                  "*Limit exceeded",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnbudgetedSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "Not budgeted this month",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        ...unbudgetedCategories.map(
          (category) => _buildUnbudgetedCard(category, theme),
        ),
      ],
    );
  }

  Widget _buildUnbudgetedCard(Map<String, dynamic> category, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
        border: Border.all(width: 0.5, color: theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category['icon'] ?? '💰',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category['name'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _openSetBudgetDialog(category),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withAlpha(450),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Set Budget",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            ImagePaths.icBudget,
            color: Theme.of(context).colorScheme.primary,
            height: 80,
          ),
          const SizedBox(height: 16),
          Text(
            "No budgets for ${DateFormat('MMMM').format(selectedDate)}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to create your first budget",
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreateBudgetDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Create Budget",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

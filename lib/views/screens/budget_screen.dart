import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/database/dao/budget_dao.dart';
import 'package:money_mirror/views/widgets/budget/create_budget_dialog.dart';
import 'package:money_mirror/views/widgets/budget/edit_budget_dialog.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Map<String, dynamic>> budgets = [];
  bool isLoading = true;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  double totalBudget = 0.0;
  double totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => isLoading = true);

    final budgetData = await BudgetDao.getBudgetsByMonthYear(
      month: selectedMonth,
      year: selectedYear,
    );

    double tempTotalBudget = 0.0;
    double tempTotalSpent = 0.0;

    // Load spent amounts for each budget
    for (var budget in budgetData) {
      final spent = await BudgetDao.getSpentAmount(
        categoryId: budget['category_id'],
        month: selectedMonth,
        year: selectedYear,
        type: budget['type'],
      );
      budget['spent'] = spent;
      tempTotalBudget += (budget['amount'] as num).toDouble();
      tempTotalSpent += spent;
    }

    setState(() {
      budgets = budgetData;
      totalBudget = tempTotalBudget;
      totalSpent = tempTotalSpent;
      isLoading = false;
    });
  }

  void _openCreateBudgetDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateBudgetDialog(
        onAdded: _loadBudgets,
        preSelectedMonth: selectedMonth,
        preSelectedYear: selectedYear,
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
        title: Text("Delete Budget?"),
        content: Text(
          "Are you sure you want to delete the budget for $categoryName?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BudgetDao.deleteBudget(id);
      _loadBudgets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Budget"),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: Icon(Icons.menu),
        ),
        actions: [
          IconButton(
            onPressed: _openCreateBudgetDialog,
            icon: Icon(Icons.add),
            tooltip: "Add Budget",
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgets,
              color: AppColors.primaryColor,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Month/Year Selector
                    _buildMonthYearSelector(),

                    // Summary Card
                    if (budgets.isNotEmpty) _buildSummaryCard(),

                    // Budget List
                    if (budgets.isEmpty)
                      _buildEmptyState()
                    else
                      _buildBudgetList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: AppColors.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: selectedMonth,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem(
                    value: month,
                    child: Text(_getMonthName(month)),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedMonth = value);
                    _loadBudgets();
                  }
                },
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedYear,
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - 1 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedYear = value);
                    _loadBudgets();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;
    final remaining = totalBudget - totalSpent;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (percentage <= 70) {
      statusColor = Colors.green;
      statusText = "On Track";
      statusIcon = Icons.check_circle;
    } else if (percentage <= 90) {
      statusColor = Colors.orange;
      statusText = "Warning";
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusText = "Over Budget";
      statusIcon = Icons.error;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.TertiaryColor, AppColors.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(30),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_getMonthName(selectedMonth)} $selectedYear",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                "Spent",
                PrefCurrencySymbol.rupee + totalSpent.toStringAsFixed(2),
                Colors.red.shade300,
              ),
              _buildSummaryItem(
                "Budget",
                PrefCurrencySymbol.rupee + totalBudget.toStringAsFixed(2),
                Colors.white,
              ),
              _buildSummaryItem(
                "Remaining",
                PrefCurrencySymbol.rupee + remaining.toStringAsFixed(2),
                remaining >= 0 ? Colors.green.shade300 : Colors.red.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: budgets.length,
        itemBuilder: (context, index) {
          final budget = budgets[index];
          return _buildBudgetCard(budget);
        },
      ),
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic> budget) {
    final amount = (budget['amount'] as num).toDouble();
    final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
    final percentage = amount > 0 ? (spent / amount) * 100 : 0.0;
    final remaining = amount - spent;

    Color progressColor;
    if (percentage <= 70) {
      progressColor = Colors.green;
    } else if (percentage <= 90) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _openEditBudgetDialog(budget),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      budget['category_icon'] ?? '💰',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget['category_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "${percentage.toStringAsFixed(1)}% used",
                          style: TextStyle(
                            fontSize: 14,
                            color: progressColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert),
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
                            Icon(Icons.edit, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage > 100 ? 1.0 : percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              SizedBox(height: 12),

              // Amount Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Spent",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 2),
                      Text(
                        PrefCurrencySymbol.rupee + spent.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Budget",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 2),
                      Text(
                        PrefCurrencySymbol.rupee + amount.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Remaining",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 2),
                      Text(
                        PrefCurrencySymbol.rupee + remaining.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: remaining >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wallet, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No budgets for ${_getMonthName(selectedMonth)}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Tap + to create your first budget",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreateBudgetDialog,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text("Create Budget", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

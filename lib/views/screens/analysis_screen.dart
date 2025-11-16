import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/analysis_utils.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Period selection
  String selectedPeriod = 'Monthly';
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime.now();

  // Data
  bool isLoading = true;
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double balance = 0.0;
  List<Map<String, dynamic>> categoryBreakdown = [];
  List<Map<String, dynamic>> dailyData = [];
  Map<String, dynamic> comparison = {};
  int transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateDateRange();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    final now = DateTime.now();

    switch (selectedPeriod) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(Duration(days: 6, hours: 23, minutes: 59));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Custom':
        break;
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final income = await AnalysisUtils.getTotalIncome(
      startDate: startDate,
      endDate: endDate,
    );
    final expense = await AnalysisUtils.getTotalExpense(
      startDate: startDate,
      endDate: endDate,
    );
    final catBreakdown = await AnalysisUtils.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      type: 'EXPENSE',
    );
    final daily = await AnalysisUtils.getDailyTransactions(
      startDate: startDate,
      endDate: endDate,
      type: 'EXPENSE',
    );

    final duration = endDate.difference(startDate);
    final prevStartDate = startDate.subtract(duration);
    final prevEndDate = startDate.subtract(Duration(seconds: 1));

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
      dailyData = daily;
      comparison = comp;
      transactionCount = counts['income']! + counts['expense']!;
      isLoading = false;
    });
  }

  Future<void> _selectCustomDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
        selectedPeriod = 'Custom';
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analysis"),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: Icon(Icons.menu),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Overview"),
            Tab(text: "Categories"),
            Tab(text: "Trends"),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPeriodSelector(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primaryColor,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildCategoriesTab(),
                        _buildTrendsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.grey.shade100,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var period in [
                  'Daily',
                  'Weekly',
                  'Monthly',
                  'Yearly',
                  'Custom',
                ])
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: selectedPeriod == period,
                      selectedColor: AppColors.primaryColor,
                      labelStyle: TextStyle(
                        color: selectedPeriod == period
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedPeriod = period;
                            if (period != 'Custom') {
                              _updateDateRange();
                              _loadData();
                            }
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (selectedPeriod == 'Custom') ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectCustomDate(true),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(startDate)),
                          Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("to"),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectCustomDate(false),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(endDate)),
                          Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: 8),
            Text(
              '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          SizedBox(height: 16),
          _buildComparisonCard(),
          SizedBox(height: 16),
          _buildInsightsCard(),
          SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        _buildSummaryCard(
          title: "Total Income",
          amount: totalIncome,
          icon: Icons.arrow_downward,
          color: Colors.green,
        ),
        SizedBox(height: 12),
        _buildSummaryCard(
          title: "Total Expenses",
          amount: totalExpense,
          icon: Icons.arrow_upward,
          color: Colors.red,
        ),
        SizedBox(height: 12),
        _buildSummaryCard(
          title: "Balance",
          amount: balance,
          icon: Icons.account_balance_wallet,
          color: balance >= 0 ? Colors.teal : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                SizedBox(height: 4),
                Text(
                  PrefCurrencySymbol.rupee + amount.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    if (comparison.isEmpty) return SizedBox.shrink();

    final expenseChange = comparison['expense_change'] as double;
    final expensePercentage = comparison['expense_percentage'] as double;
    final isIncrease = expenseChange > 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: AppColors.primaryColor),
                SizedBox(width: 8),
                Text(
                  "Period Comparison",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Expense Change:"),
                Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.trending_up : Icons.trending_down,
                      color: isIncrease ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${expensePercentage.abs().toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncrease ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              isIncrease
                  ? "You spent ${PrefCurrencySymbol.rupee}${expenseChange.toStringAsFixed(2)} more than the previous period"
                  : "You saved ${PrefCurrencySymbol.rupee}${expenseChange.abs().toStringAsFixed(2)} compared to the previous period",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    final avgDaily = totalExpense / (endDate.difference(startDate).inDays + 1);
    final topCategory = categoryBreakdown.isNotEmpty
        ? categoryBreakdown.first
        : null;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  "Insights",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            _buildInsightRow(
              Icons.calendar_today,
              "Average daily spending",
              PrefCurrencySymbol.rupee + avgDaily.toStringAsFixed(2),
            ),
            if (topCategory != null)
              _buildInsightRow(
                Icons.trending_up,
                "Highest spending category",
                "${topCategory['category_name']} (${PrefCurrencySymbol.rupee}${(topCategory['total'] as num).toDouble().toStringAsFixed(2)})",
              ),
            _buildInsightRow(
              Icons.receipt,
              "Total transactions",
              transactionCount.toString(),
            ),
            if (balance < 0)
              _buildInsightRow(
                Icons.warning,
                "Warning",
                "Expenses exceed income",
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Stats",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Income", totalIncome, Colors.green),
                Container(width: 1, height: 40, color: Colors.grey),
                _buildStatItem("Expense", totalExpense, Colors.red),
                Container(width: 1, height: 40, color: Colors.grey),
                _buildStatItem(
                  "Savings",
                  balance,
                  balance >= 0 ? Colors.teal : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 4),
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

  Widget _buildCategoriesTab() {
    if (categoryBreakdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No expense data available",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final total = categoryBreakdown.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as num).toDouble(),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPieChart(),
          SizedBox(height: 24),
          _buildCategoryList(total),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    final sections = categoryBreakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = (data['total'] as num).toDouble();
      final color = colors[index % colors.length];

      return PieChartSectionData(
        value: value,
        title: '',
        color: color,
        radius: 100,
      );
    }).toList();

    return Container(
      height: 250,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Expense Distribution",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(double total) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    return Card(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Category Breakdown",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Total: ${PrefCurrencySymbol.rupee}${total.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: categoryBreakdown.length,
            itemBuilder: (context, index) {
              final data = categoryBreakdown[index];
              final amount = (data['total'] as num).toDouble();
              final percentage = (amount / total) * 100;
              final color = colors[index % colors.length];

              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['category_icon'] ?? '💰',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(data['category_name'] ?? 'Unknown'),
                subtitle: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PrefCurrencySymbol.rupee + amount.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${percentage.toStringAsFixed(1)}%",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (dailyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No trend data available",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [_buildLineChart(), SizedBox(height: 24), _buildBarChart()],
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = dailyData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = (entry.value['total'] as num).toDouble();
      return FlSpot(index, value);
    }).toList();

    return Container(
      height: 300,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Spending Trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
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
                                style: TextStyle(fontSize: 10),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primaryColor,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final barGroups = dailyData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value['total'] as num).toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: AppColors.primaryColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 300,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Expenses (Bar Chart)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
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
                                style: TextStyle(fontSize: 10),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

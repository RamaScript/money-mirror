import 'package:money_mirror/database/db_handler.dart';

class AnalysisUtils {
  // Get total income for a date range
  static Future<double> getTotalIncome({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = 'INCOME'
        AND date >= ?
        AND date <= ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total expense for a date range
  static Future<double> getTotalExpense({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = 'EXPENSE'
        AND date >= ?
        AND date <= ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get category-wise breakdown for expenses
  static Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
    required String type,
  }) async {
    final db = await DBHandler().database;
    return await db.rawQuery(
      '''
      SELECT 
        c.name as category_name,
        c.icon as category_icon,
        c.id as category_id,
        SUM(t.amount) as total,
        COUNT(t.id) as transaction_count
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.type = ?
        AND t.date >= ?
        AND t.date <= ?
      GROUP BY t.category_id
      ORDER BY total DESC
    ''',
      [type, startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  // Get daily transactions for a date range
  static Future<List<Map<String, dynamic>>> getDailyTransactions({
    required DateTime startDate,
    required DateTime endDate,
    required String type,
  }) async {
    final db = await DBHandler().database;
    return await db.rawQuery(
      '''
      SELECT 
        DATE(date) as day,
        SUM(amount) as total
      FROM transactions
      WHERE type = ?
        AND date >= ?
        AND date <= ?
      GROUP BY DATE(date)
      ORDER BY date ASC
    ''',
      [type, startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  // Get monthly summary
  static Future<Map<String, dynamic>> getMonthlySummary({
    required int month,
    required int year,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final income = await getTotalIncome(startDate: startDate, endDate: endDate);
    final expense = await getTotalExpense(
      startDate: startDate,
      endDate: endDate,
    );
    final balance = income - expense;

    final db = await DBHandler().database;

    // Transaction count
    final countResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM transactions 
      WHERE date >= ? AND date <= ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return {
      'income': income,
      'expense': expense,
      'balance': balance,
      'transaction_count': countResult.first['count'] as int,
      'month': month,
      'year': year,
    };
  }

  // Get top spending categories
  static Future<List<Map<String, dynamic>>> getTopSpendingCategories({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    final breakdown = await getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      type: 'EXPENSE',
    );
    return breakdown.take(limit).toList();
  }

  // Compare two periods
  static Future<Map<String, dynamic>> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) async {
    final period1Income = await getTotalIncome(
      startDate: period1Start,
      endDate: period1End,
    );
    final period1Expense = await getTotalExpense(
      startDate: period1Start,
      endDate: period1End,
    );

    final period2Income = await getTotalIncome(
      startDate: period2Start,
      endDate: period2End,
    );
    final period2Expense = await getTotalExpense(
      startDate: period2Start,
      endDate: period2End,
    );

    final incomeChange = period1Income - period2Income;
    final expenseChange = period1Expense - period2Expense;

    final incomePercentage = period2Income > 0
        ? ((incomeChange / period2Income) * 100)
        : 0.0;
    final expensePercentage = period2Expense > 0
        ? ((expenseChange / period2Expense) * 100)
        : 0.0;

    return {
      'period1_income': period1Income,
      'period1_expense': period1Expense,
      'period2_income': period2Income,
      'period2_expense': period2Expense,
      'income_change': incomeChange,
      'expense_change': expenseChange,
      'income_percentage': incomePercentage,
      'expense_percentage': expensePercentage,
    };
  }

  // Get weekly summary for current week
  static Future<List<Map<String, dynamic>>> getWeeklySummary() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return getDailyTransactions(
      startDate: startOfWeek,
      endDate: endOfWeek,
      type: 'EXPENSE',
    );
  }

  // Get transaction count by type for a date range
  static Future<Map<String, int>> getTransactionCounts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;

    final incomeResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM transactions 
      WHERE type = 'INCOME' AND date >= ? AND date <= ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final expenseResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM transactions 
      WHERE type = 'EXPENSE' AND date >= ? AND date <= ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return {
      'income': incomeResult.first['count'] as int,
      'expense': expenseResult.first['count'] as int,
    };
  }

  // Get average daily spending
  static Future<double> getAverageDailySpending({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final totalExpense = await getTotalExpense(
      startDate: startDate,
      endDate: endDate,
    );

    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? totalExpense / days : 0.0;
  }

  // Get account-wise breakdown
  static Future<List<Map<String, dynamic>>> getAccountBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;
    return await db.rawQuery(
      '''
      SELECT 
        a.id as account_id,
        a.name as account_name,
        a.icon as account_icon,
        SUM(CASE WHEN t.type = 'INCOME' THEN t.amount ELSE 0 END) as income,
        SUM(CASE WHEN t.type = 'EXPENSE' THEN t.amount ELSE 0 END) as expense
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.date >= ? AND t.date <= ?
      GROUP BY t.account_id
      ORDER BY a.name ASC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  // Get daily income transactions
  static Future<List<Map<String, dynamic>>> getDailyIncome({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;
    return await db.rawQuery(
      '''
      SELECT 
        DATE(date) as day,
        SUM(amount) as total
      FROM transactions
      WHERE type = 'INCOME'
        AND date >= ? AND date <= ?
      GROUP BY DATE(date)
      ORDER BY date ASC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }
}

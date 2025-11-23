import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/transaction_table.dart';

class TransactionDao {
  static Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await DBHandler().database;
    return await db.insert(TransactionTable.tableName, data);
  }

  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await DBHandler().database;
    // Join with accounts and categories to get their names and icons
    return await db.rawQuery('''
      SELECT 
        t.*,
        a.name as account_name,
        a.icon as account_icon,
        c.name as category_name,
        c.icon as category_icon
      FROM ${TransactionTable.tableName} t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN categories c ON t.category_id = c.id
      ORDER BY t.date DESC, t.id DESC
    ''');
  }

  static Future<List<Map<String, dynamic>>> getTransactionsByType({
    required String type,
  }) async {
    final db = await DBHandler().database;
    return await db.rawQuery(
      '''
      SELECT 
        t.*,
        a.name as account_name,
        a.icon as account_icon,
        c.name as category_name,
        c.icon as category_icon
      FROM ${TransactionTable.tableName} t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.type = ?
      ORDER BY t.date DESC, t.id DESC
    ''',
      [type.toUpperCase()],
    );
  }

  static Future<void> deleteTransaction(int id) async {
    final db = await DBHandler().database;
    await db.delete(
      TransactionTable.tableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<void> updateTransaction({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final db = await DBHandler().database;
    await db.update(
      TransactionTable.tableName,
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // Get total income
  static Future<double> getTotalIncome() async {
    final db = await DBHandler().database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM ${TransactionTable.tableName} 
      WHERE type = 'INCOME'
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total expense
  static Future<double> getTotalExpense() async {
    final db = await DBHandler().database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM ${TransactionTable.tableName} 
      WHERE type = 'EXPENSE'
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get transactions by date range
  static Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;
    return await db.rawQuery(
      '''
      SELECT 
        t.*,
        a.name as account_name,
        a.icon as account_icon,
        c.name as category_name,
        c.icon as category_icon
      FROM ${TransactionTable.tableName} t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.date >= ? AND t.date <= ?
      ORDER BY t.date DESC, t.id DESC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  // Get total income by date range
  static Future<double> getTotalIncomeByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM ${TransactionTable.tableName} 
      WHERE type = 'INCOME' AND date >= ? AND date <= ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total expense by date range
  static Future<double> getTotalExpenseByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DBHandler().database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM ${TransactionTable.tableName} 
      WHERE type = 'EXPENSE' AND date >= ? AND date <= ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total expense grouped by account in 1 query
  static Future<Map<int, double>> getExpensesGrouped() async {
    final db = await DBHandler().database;
    final result = await db.rawQuery('''
      SELECT account_id, SUM(amount) as total 
      FROM ${TransactionTable.tableName}
      WHERE type = 'EXPENSE'
      GROUP BY account_id
    ''');

    return {
      for (var row in result)
        row['account_id'] as int: (row['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // Get total income grouped by account in 1 query
  static Future<Map<int, double>> getIncomeGrouped() async {
    final db = await DBHandler().database;
    final result = await db.rawQuery('''
      SELECT account_id, SUM(amount) as total 
      FROM ${TransactionTable.tableName}
      WHERE type = 'INCOME'
      GROUP BY account_id
    ''');

    return {
      for (var row in result)
        row['account_id'] as int: (row['total'] as num?)?.toDouble() ?? 0.0,
    };
  }
}

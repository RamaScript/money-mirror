import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/transaction_table.dart';

class TransactionDao {
  static Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await DBHandler().database;
    return await db.insert(TransactionTable.tableName, data);
  }

  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await DBHandler().database;
    return await db.rawQuery('''
      SELECT 
        t.*,
        a.name as account_name,
        a.icon as account_icon,
        c.name as category_name,
        c.icon as category_icon,
        ta.name as to_account_name,
        ta.icon as to_account_icon
      FROM ${TransactionTable.tableName} t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts ta ON t.to_account_id = ta.id
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
        c.icon as category_icon,
        ta.name as to_account_name,
        ta.icon as to_account_icon
      FROM ${TransactionTable.tableName} t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts ta ON t.to_account_id = ta.id
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

  // Get total income (EXCLUDING TRANSFERS)
  static Future<double> getTotalIncome() async {
    final db = await DBHandler().database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM ${TransactionTable.tableName} 
      WHERE type = 'INCOME'
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total expense (EXCLUDING TRANSFERS)
  static Future<double> getTotalExpense() async {
    final db = await DBHandler().database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM ${TransactionTable.tableName} 
      WHERE type = 'EXPENSE'
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get transactions by date range (INCLUDING TRANSFERS)
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
        c.icon as category_icon,
        ta.name as to_account_name,
        ta.icon as to_account_icon
      FROM ${TransactionTable.tableName} t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts ta ON t.to_account_id = ta.id
      WHERE t.date >= ? AND t.date <= ?
      ORDER BY t.date DESC, t.id DESC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  // Get total income by date range (EXCLUDING TRANSFERS)
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

  // Get total expense by date range (EXCLUDING TRANSFERS)
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

  // Get total expense grouped by account (EXCLUDING TRANSFERS)
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

  // Get total income grouped by account (EXCLUDING TRANSFERS)
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

  // NEW: Get transfer impact on accounts
  static Future<Map<int, double>> getTransferImpact() async {
    final db = await DBHandler().database;

    // Get amounts transferred OUT (negative impact)
    final transferOut = await db.rawQuery('''
      SELECT account_id, SUM(amount) as total 
      FROM ${TransactionTable.tableName}
      WHERE type = 'TRANSFER' AND to_account_id IS NOT NULL
      GROUP BY account_id
    ''');

    // Get amounts transferred IN (positive impact)
    final transferIn = await db.rawQuery('''
      SELECT to_account_id as account_id, SUM(amount) as total 
      FROM ${TransactionTable.tableName}
      WHERE type = 'TRANSFER' AND to_account_id IS NOT NULL
      GROUP BY to_account_id
    ''');

    final Map<int, double> impact = {};

    // Subtract transfers out
    for (var row in transferOut) {
      final accountId = row['account_id'] as int;
      final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
      impact[accountId] = (impact[accountId] ?? 0.0) - amount;
    }

    // Add transfers in
    for (var row in transferIn) {
      final accountId = row['account_id'] as int;
      final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
      impact[accountId] = (impact[accountId] ?? 0.0) + amount;
    }

    return impact;
  }
}

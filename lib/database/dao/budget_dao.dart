import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/budget_table.dart';

class BudgetDao {
  // Insert budget
  static Future<int> insertBudget(Map<String, dynamic> data) async {
    final db = await DBHandler().database;
    return await db.insert(BudgetTable.tableName, data);
  }

  // Get all budgets with category details
  static Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await DBHandler().database;
    return await db.rawQuery('''
      SELECT 
        b.*,
        c.name as category_name,
        c.icon as category_icon,
        c.type as category_type
      FROM ${BudgetTable.tableName} b
      LEFT JOIN categories c ON b.category_id = c.id
      ORDER BY b.year DESC, b.month DESC
    ''');
  }

  // Get budgets by month and year
  static Future<List<Map<String, dynamic>>> getBudgetsByMonthYear({
    required int month,
    required int year,
  }) async {
    final db = await DBHandler().database;
    return await db.rawQuery(
      '''
      SELECT 
        b.*,
        c.name as category_name,
        c.icon as category_icon,
        c.type as category_type
      FROM ${BudgetTable.tableName} b
      LEFT JOIN categories c ON b.category_id = c.id
      WHERE b.month = ? AND b.year = ?
      ORDER BY c.name ASC
    ''',
      [month, year],
    );
  }

  // Get spent amount for a budget
  static Future<double> getSpentAmount({
    required int categoryId,
    required int month,
    required int year,
    required String type,
  }) async {
    final db = await DBHandler().database;

    // Calculate start and end dates for the month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE category_id = ? 
        AND type = ?
        AND date >= ?
        AND date <= ?
    ''',
      [
        categoryId,
        type,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Check if budget already exists
  static Future<bool> budgetExists({
    required int categoryId,
    required int month,
    required int year,
    int? excludeId,
  }) async {
    final db = await DBHandler().database;

    String query =
        '''
      SELECT COUNT(*) as count 
      FROM ${BudgetTable.tableName} 
      WHERE category_id = ? AND month = ? AND year = ?
    ''';

    List<dynamic> args = [categoryId, month, year];

    if (excludeId != null) {
      query += ' AND id != ?';
      args.add(excludeId);
    }

    final result = await db.rawQuery(query, args);
    final count = result.first['count'] as int;
    return count > 0;
  }

  // Update budget
  static Future<void> updateBudget({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final db = await DBHandler().database;
    await db.update(
      BudgetTable.tableName,
      data,
      where: "id = ? ",
      whereArgs: [id],
    );
  }

  // Delete budget
  static Future<void> deleteBudget(int id) async {
    final db = await DBHandler().database;
    await db.delete(BudgetTable.tableName, where: "id = ? ", whereArgs: [id]);
  }

  // Get budget by category for current month
  static Future<Map<String, dynamic>?> getBudgetForCategory({
    required int categoryId,
    required int month,
    required int year,
  }) async {
    final db = await DBHandler().database;
    final result = await db.rawQuery(
      '''
      SELECT 
        b.*,
        c.name as category_name,
        c.icon as category_icon
      FROM ${BudgetTable.tableName} b
      LEFT JOIN categories c ON b.category_id = c.id
      WHERE b.category_id = ? AND b.month = ? AND b.year = ?
      LIMIT 1
    ''',
      [categoryId, month, year],
    );

    return result.isNotEmpty ? result.first : null;
  }
}

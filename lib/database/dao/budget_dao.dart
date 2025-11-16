import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/budget_table.dart';

class BudgetDao {
  // Insert budget
  static Future<int> insertBudget(Map<String, dynamic> data) async {
    final db = await DBHandler().database;
    appLog("💾 [BudgetDao] Inserting budget: $data");
    final result = await db.insert(BudgetTable.tableName, data);
    appLog("✅ [BudgetDao] Budget inserted with ID: $result");
    return result;
  }

  // Get all budgets with category details
  static Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await DBHandler().database;
    appLog("🔍 [BudgetDao] Fetching all budgets...");

    // First check what columns actually exist
    final tableInfo = await db.rawQuery(
      "PRAGMA table_info(${BudgetTable.tableName})",
    );
    appLog("📋 [BudgetDao] Budget table columns: $tableInfo");

    final result = await db.rawQuery('''
      SELECT 
        b.*,
        c.name as category_name,
        c.icon as category_icon,
        c.type as category_type
      FROM ${BudgetTable.tableName} b
      LEFT JOIN categories c ON b.category_id = c.id
      ORDER BY b.year DESC, b.month DESC
    ''');

    appLog("📊 [BudgetDao] Found ${result.length} total budgets");
    return result;
  }

  // Get budgets by month and year - FIXED VERSION
  static Future<List<Map<String, dynamic>>> getBudgetsByMonthYear({
    required int month,
    required int year,
  }) async {
    final db = await DBHandler().database;
    appLog("🔍 [BudgetDao] Searching budgets for month=$month, year=$year");

    // Debug: Check what's in the table
    final allBudgets = await db.rawQuery(
      'SELECT * FROM ${BudgetTable.tableName}',
    );
    appLog("🗃️ [BudgetDao] Total budgets in DB: ${allBudgets.length}");
    for (var budget in allBudgets) {
      appLog(
        "   - Budget ID ${budget['id']}: month=${budget['month']}, year=${budget['year']}, category_id=${budget['category_id']}",
      );
    }

    // Try query with column name variations
    List<Map<String, dynamic>> result;
    try {
      // Try with spaces first (old database)
      result = await db.rawQuery(
        '''
        SELECT 
          b.*,
          c.name as category_name,
          c.icon as category_icon,
          c.type as category_type
        FROM ${BudgetTable.tableName} b
        LEFT JOIN categories c ON b.category_id = c.id
        WHERE b.[month ] = ? AND b.[year ] = ?
        ORDER BY c.name ASC
      ''',
        [month, year],
      );
      appLog(
        "✅ [BudgetDao] Query with spaces succeeded: ${result.length} results",
      );
    } catch (e) {
      appLog("⚠️ [BudgetDao] Query with spaces failed: $e");
      // Try without spaces
      result = await db.rawQuery(
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
      appLog(
        "✅ [BudgetDao] Query without spaces succeeded: ${result.length} results",
      );
    }

    appLog("🎯 [BudgetDao] Filtered results: ${result.length} budgets");
    for (var budget in result) {
      appLog("   - ${budget['category_name']}: ${budget['amount']}");
    }

    return result;
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

    appLog(
      "💸 [BudgetDao] Calculating spent for category=$categoryId, month=$month, year=$year, type=$type",
    );
    appLog(
      "   Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}",
    );

    // FIRST CHECK: Get ALL transactions for this category (ignore type)
    final debugResult = await db.rawQuery(
      '''
    SELECT * FROM transactions 
    WHERE category_id = ? 
      AND date >= ?
      AND date <= ?
    ''',
      [categoryId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    appLog(
      "   DEBUG: Found ${debugResult.length} total transactions for this category",
    );
    for (var txn in debugResult) {
      appLog(
        "      Transaction: type=${txn['type']}, amount=${txn['amount']}, date=${txn['date']}",
      );
    }

    // NOW CHECK WITH TYPE FILTER
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

    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    appLog("   Spent (with type filter): $total");
    return total;
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

    try {
      final result = await db.rawQuery(query, args);
      final count = result.first['count'] as int;
      appLog("🔍 [BudgetDao] Budget exists check: count=$count");
      return count > 0;
    } catch (e) {
      appLog("⚠️ [BudgetDao] Error checking budget exists: $e");
      // Try with spaces
      query =
          '''
        SELECT COUNT(*) as count 
        FROM ${BudgetTable.tableName} 
        WHERE category_id = ? AND [month ] = ? AND [year ] = ?
      ''';
      if (excludeId != null) {
        query += ' AND id != ?';
      }
      final result = await db.rawQuery(query, args);
      final count = result.first['count'] as int;
      appLog("🔍 [BudgetDao] Budget exists check (with spaces): count=$count");
      return count > 0;
    }
  }

  // Update budget
  static Future<void> updateBudget({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final db = await DBHandler().database;
    appLog("📝 [BudgetDao] Updating budget ID=$id with data: $data");
    await db.update(
      BudgetTable.tableName,
      data,
      where: "id = ? ",
      whereArgs: [id],
    );
    appLog("✅ [BudgetDao] Budget updated successfully");
  }

  // Delete budget
  static Future<void> deleteBudget(int id) async {
    final db = await DBHandler().database;
    appLog("🗑️ [BudgetDao] Deleting budget ID=$id");
    await db.delete(BudgetTable.tableName, where: "id = ? ", whereArgs: [id]);
    appLog("✅ [BudgetDao] Budget deleted successfully");
  }

  // Get budget by category for current month
  static Future<Map<String, dynamic>?> getBudgetForCategory({
    required int categoryId,
    required int month,
    required int year,
  }) async {
    final db = await DBHandler().database;
    appLog(
      "🔍 [BudgetDao] Getting budget for category=$categoryId, month=$month, year=$year",
    );

    List<Map<String, dynamic>> result;
    try {
      // Try with spaces
      result = await db.rawQuery(
        '''
        SELECT 
          b.*,
          c.name as category_name,
          c.icon as category_icon
        FROM ${BudgetTable.tableName} b
        LEFT JOIN categories c ON b.category_id = c.id
        WHERE b.category_id = ? AND b.[month ] = ? AND b.[year ] = ?
        LIMIT 1
      ''',
        [categoryId, month, year],
      );
    } catch (e) {
      // Try without spaces
      result = await db.rawQuery(
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
    }

    final budget = result.isNotEmpty ? result.first : null;
    appLog("   Result: ${budget != null ? 'Found' : 'Not found'}");
    return budget;
  }
}

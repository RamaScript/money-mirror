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
}

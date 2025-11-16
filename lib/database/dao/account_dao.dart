import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/account_table.dart';

class AccountDao {
  static Future<int> insertAccount(Map<String, dynamic> data) async {
    final db = await DBHandler().database;
    return await db.insert(AccountTable.tableName, data);
  }

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await DBHandler().database;

    return db.query(AccountTable.tableName, orderBy: "name ASC");
  }

  static Future<void> deleteAccount(int id) async {
    final db = await DBHandler().database;
    // whereArgs = SQL injection se bachane ke liye  safe binding
    await db.delete(AccountTable.tableName, where: "id = ?", whereArgs: [id]);
  }

  static Future<void> updateAccount({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final db = await DBHandler().database;
    await db.update(
      AccountTable.tableName,
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }
}

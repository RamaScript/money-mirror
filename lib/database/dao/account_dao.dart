import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/account_table.dart';

class AccountDao {
  static Future<int> insertAccount(Map<String, dynamic> data) async {
    final db = await DBHandler().database;

    // If icon is null or empty → set default
    data[AccountTable.colIcon] ??= '🏦';

    // If someone passes "" (empty string), also fix it
    if ((data[AccountTable.colIcon] as String).trim().isEmpty) {
      data[AccountTable.colIcon] = '🏦';
    }

    return await db.insert(AccountTable.tableName, data);
  }

  static Future<int> getOrCreate(String name) async {
    final db = await DBHandler().database;

    final res = await db.query(
      AccountTable.tableName,
      where: "${AccountTable.colName} = ?",
      whereArgs: [name],
      limit: 1,
    );

    if (res.isNotEmpty) return res.first["id"] as int;

    return await db.insert(AccountTable.tableName, {
      AccountTable.colName: name,
      AccountTable.colIcon: '🏦',
      AccountTable.colInitialAmount: 0.0,
    });
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

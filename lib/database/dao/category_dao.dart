import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/category_table.dart';

class CategoryDao {
  static Future<int> insertCategory(Map<String, dynamic> data) async {
    final db = await DBHandler().database;
    return await db.insert(CategoryTable.tableName, data);
  }

  static Future<int> getOrCreate(String name, {String type = "OTHERS"}) async {
    final db = await DBHandler().database;

    final res = await db.query(
      CategoryTable.tableName,
      where: "${CategoryTable.colName} = ? AND ${CategoryTable.colType} = ?",
      whereArgs: [name, type],
      limit: 1,
    );

    if (res.isNotEmpty) return res.first["id"] as int;

    return await db.insert(CategoryTable.tableName, {
      CategoryTable.colName: name,
      CategoryTable.colIcon: type == "INCOME" ? '💵' : '💸',
      CategoryTable.colType: type, // or default type
    });
  }

  static Future<List<Map<String, dynamic>>> getCategories({
    String? type,
  }) async {
    final db = await DBHandler().database;
    if (type == null) {
      return db.query(CategoryTable.tableName, orderBy: "name ASC");
    }
    return db.query(
      CategoryTable.tableName,
      orderBy: "name ASC",
      where: "type = ?",
      whereArgs: [type.toUpperCase()],
    );
  }

  static Future<void> deleteCategory(int id) async {
    final db = await DBHandler().database;
    await db.delete(CategoryTable.tableName, where: "id = ?", whereArgs: [id]);
  }

  static Future<void> updateCategory({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final db = await DBHandler().database;
    await db.update(
      CategoryTable.tableName,
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }
}

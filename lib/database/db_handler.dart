import 'package:money_mirror/database/schema/account_table.dart';
import 'package:money_mirror/database/schema/budget_table.dart';
import 'package:money_mirror/database/schema/category_table.dart';
import 'package:money_mirror/database/schema/transaction_table.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHandler {
  static Database? _db;

  // 1) DATABASE GETTER (Singleton)
  Future<Database> get database async {
    // agar database already open hai → wahi return karo
    if (_db != null) return _db!;

    // warna database initialize karo (open/create)
    _db = await initDB();
    return _db!;
  }

  // 2) initDB() → Database open karta hai
  Future<Database> initDB() async {
    // SQLite ko ek directory milti hai jaha database files store hoti hain
    final dbPath = await getDatabasesPath();

    // join() safe tarike se path banata hai
    // Example: /data/user/0/app/databases/money_mirror.db
    final path = join(dbPath, "money_mirror.db");

    // openDatabase:
    // - agar file exist karti hai → open it
    // - agar file exist nahi karti → create kar do + onCreate call karo
    return await openDatabase(
      path,
      version:
          1, // DB version → future me schema change karoge to update yahi karoge
      onCreate:
          _createTables, // jab DB first time banta hai tab yeh call hota hai
    );
  }

  // 3) _createTables() → Yaha saare CREATE TABLE queries aayenge
  Future<void> _createTables(Database db, int version) async {
    // First create categories and accounts (no dependencies)
    await db.execute(CategoryTable.createTable);
    await db.execute(AccountTable.createTable);

    // Then create transactions (depends on categories and accounts)
    await db.execute(TransactionTable.createTable);

    await db.execute(BudgetTable.createTable);
  }

  // 4) _onUpgrade() → For upgrading existing databases
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add budgets table for version 2
      await db.execute(BudgetTable.createTable);
    }
  }
}

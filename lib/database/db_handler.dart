import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/database/schema/account_table.dart';
import 'package:money_mirror/database/schema/budget_table.dart';
import 'package:money_mirror/database/schema/category_table.dart';
import 'package:money_mirror/database/schema/transaction_table.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHandler {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "money_mirror.db");

    return await openDatabase(
      path,
      version: 3, // ✅ Increased version for transfer migration
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute(CategoryTable.createTable);
    await db.execute(AccountTable.createTable);
    await db.execute(TransactionTable.createTable);
    await db.execute(BudgetTable.createTable);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    appLog(
      "🔄 [DBHandler] Upgrading database from v$oldVersion to v$newVersion",
    );

    if (oldVersion < 2) {
      // Budget table migration (existing code)
      appLog("🔄 [DBHandler] Migrating budget table...");
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            month INTEGER NOT NULL,
            year INTEGER NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
            UNIQUE(category_id, month, year)
          )
        ''');

        await db.execute('''
          INSERT INTO budgets_new (id, category_id, month, year, amount, type)
          SELECT id, category_id, month, year, amount, [type  ]
          FROM budgets
        ''');

        await db.execute('DROP TABLE budgets');
        await db.execute('ALTER TABLE budgets_new RENAME TO budgets');
        appLog("✅ [DBHandler] Budget table migration completed!");
      } catch (e) {
        appLog("❌ [DBHandler] Migration error: $e");
        await db.execute('DROP TABLE IF EXISTS budgets');
        await db.execute(BudgetTable.createTable);
        appLog("⚠️ [DBHandler] Created fresh budget table (old data lost)");
      }
    }

    if (oldVersion < 3) {
      // Add to_account_id column for transfers
      appLog("🔄 [DBHandler] Adding to_account_id column for transfers...");
      try {
        await db.execute('''
          ALTER TABLE transactions ADD COLUMN to_account_id INTEGER
        ''');
        appLog("✅ [DBHandler] to_account_id column added!");

        // Delete old duplicate transfer transactions
        appLog("🗑️ [DBHandler] Cleaning up old transfer transactions...");
        // Keep only one transfer transaction per unique date+amount combination
        await db.execute('''
          DELETE FROM transactions 
          WHERE type = 'TRANSFER' 
          AND id NOT IN (
            SELECT MIN(id) 
            FROM transactions 
            WHERE type = 'TRANSFER' 
            GROUP BY date, amount, account_id
          )
        ''');
        appLog("✅ [DBHandler] Old transfer transactions cleaned up!");
      } catch (e) {
        appLog(
          "⚠️ [DBHandler] Column might already exist or cleanup failed: $e",
        );
      }
    }
  }
}

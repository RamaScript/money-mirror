import 'package:money_mirror/core/utils/log_utils.dart';
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
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  // 2) initDB() → Database open karta hai
  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "money_mirror.db");

    return await openDatabase(
      path,
      version: 2, // ✅ Version badhaya for migration
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  // 3) _createTables() → Yaha saare CREATE TABLE queries aayenge
  Future<void> _createTables(Database db, int version) async {
    await db.execute(CategoryTable.createTable);
    await db.execute(AccountTable.createTable);
    await db.execute(TransactionTable.createTable);
    await db.execute(BudgetTable.createTable);
  }

  // 4) _onUpgrade() → For upgrading existing databases
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    appLog(
      "🔄 [DBHandler] Upgrading database from v$oldVersion to v$newVersion",
    );

    if (oldVersion < 2) {
      // Fix budget table column names
      appLog("🔄 [DBHandler] Migrating budget table...");

      try {
        // Create new budget table with correct column names
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

        // Copy data from old table (handling column name with spaces)
        await db.execute('''
          INSERT INTO budgets_new (id, category_id, month, year, amount, type)
          SELECT id, category_id, month, year, amount, [type  ]
          FROM budgets
        ''');

        // Drop old table
        await db.execute('DROP TABLE budgets');

        // Rename new table
        await db.execute('ALTER TABLE budgets_new RENAME TO budgets');

        appLog("✅ [DBHandler] Budget table migration completed!");
      } catch (e) {
        appLog("❌ [DBHandler] Migration error: $e");
        // If migration fails, just create fresh budget table
        await db.execute('DROP TABLE IF EXISTS budgets');
        await db.execute(BudgetTable.createTable);
        appLog("⚠️ [DBHandler] Created fresh budget table (old data lost)");
      }
    }
  }
}

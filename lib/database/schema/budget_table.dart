class BudgetTable {
  static const String tableName = "budgets";

  static const String colId = "id";
  static const String colCategoryId = "category_id";
  static const String colMonth = "month";
  static const String colYear = "year";
  static const String colAmount = "amount";
  static const String colType = "type"; // ✅ FIXED: Removed extra spaces

  static const String createTable =
      """
  CREATE TABLE $tableName (
  $colId INTEGER PRIMARY KEY AUTOINCREMENT,
  $colCategoryId INTEGER NOT NULL,
  $colMonth INTEGER NOT NULL,
  $colYear INTEGER NOT NULL,
  $colAmount REAL NOT NULL,
  $colType TEXT NOT NULL,
  FOREIGN KEY ($colCategoryId) REFERENCES categories(id) ON DELETE CASCADE,
  UNIQUE($colCategoryId, $colMonth, $colYear)
  );
    """;
}

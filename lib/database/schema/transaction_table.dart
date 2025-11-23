class TransactionTable {
  static const String tableName = "transactions";

  static const String colId = "id";
  static const String colAmount = "amount";
  static const String colType = "type";
  static const String colAccountId = "account_id";
  static const String colCategoryId = "category_id";
  static const String colDate = "date";
  static const String colNote = "note";
  static const String colToAccountId = "to_account_id"; // NEW

  static const String createTable =
      """
    CREATE TABLE $tableName (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colAmount REAL NOT NULL,
      $colType TEXT NOT NULL,
      $colAccountId INTEGER NOT NULL,
      $colCategoryId INTEGER NOT NULL,
      $colDate TEXT NOT NULL,
      $colNote TEXT,
      $colToAccountId INTEGER,
      FOREIGN KEY ($colAccountId) REFERENCES accounts(id) ON DELETE CASCADE,
      FOREIGN KEY ($colCategoryId) REFERENCES categories(id) ON DELETE CASCADE,
      FOREIGN KEY ($colToAccountId) REFERENCES accounts(id) ON DELETE CASCADE
    );
  """;
}

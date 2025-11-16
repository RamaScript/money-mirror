class AccountTable {
  static const String tableName = "accounts";

  static const String colId = "id";
  static const String colName = "name";
  static const String colIcon = "icon";
  static const String colInitialAmount = "initial_amount";

  static const String createTable =
      """
    CREATE TABLE $tableName (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colName TEXT NOT NULL,
      $colIcon TEXT,
      $colInitialAmount REAL NOT NULL
    );
  """;
}

class CategoryTable {
  static const String tableName = "categories";

  static const String colId = "id";
  static const String colName = "name";
  static const String colIcon = "icon";
  static const String colType = "type";

  static const String createTable =
      """
    CREATE TABLE $tableName (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colName TEXT NOT NULL,
      $colIcon TEXT,
      $colType TEXT NOT NULL
    );
  """;
}

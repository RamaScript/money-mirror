class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // INCOME / EXPENSE
  final int accountId;
  final int categoryId;
  final String date; // Store as TEXT in SQLite (ISO 8601 format)
  final String? note;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.date,
    this.note,
  });

  // Convert to Map for database insert
  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,
      "title": title,
      "amount": amount,
      "type": type,
      "account_id": accountId,
      "category_id": categoryId,
      "date": date,
      "note": note,
    };
  }

  // Convert from Map (from database)
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map["id"],
      title: map["title"],
      amount: (map["amount"] ?? 0).toDouble(),
      type: map["type"],
      accountId: map["account_id"],
      categoryId: map["category_id"],
      date: map["date"],
      note: map["note"],
    );
  }
}

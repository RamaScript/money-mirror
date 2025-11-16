class BudgetModel {
  final int? id;
  final int categoryId;
  final int month; // 1-12
  final int year;
  final double amount;
  final String type; // INCOME or EXPENSE

  BudgetModel({
    this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id ": id,
      "category_id ": categoryId,
      "month ": month,
      "year ": year,
      "amount ": amount,
      "type ": type,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map["id "],
      categoryId: map["category_id "],
      month: map["month "],
      year: map["year "],
      amount: (map["amount "] ?? 0).toDouble(),
      type: map["type "],
    );
  }
}

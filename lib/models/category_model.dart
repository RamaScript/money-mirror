class CategoryModel {
  // id nullable hai (int?) because jab insert karte ho,
  // tum ID nahi doge → SQLite khud banayega
  final int? id;

  final String name;
  final String icon;
  final String type; // INCOME / EXPENSE stored as TEXT

  CategoryModel({
    this.id, // null allowed at insert time
    required this.name,
    required this.icon,
    required this.type,
  });

  // Map me convert (for INSERT)
  Map<String, dynamic> toMap() {
    return {
      // id NAHI bhejna karena SQLite auto-generate karega
      "name": name,
      "icon": icon,
      "type": type,
    };
  }

  // fromMap → DB se aaye row ko model me convert
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map["id"], // INTEGER
      name: map["name"], // TEXT
      icon: map["icon"] ?? "", // Handle null icon
      type: map["type"], // TEXT (INCOME/EXPENSE)
    );
  }
}

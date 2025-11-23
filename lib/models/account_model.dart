class AccountModel {
  final int? id;
  final String name;
  final String icon;
  final double initialAmount;
  double balance;

  AccountModel({
    this.id,
    required this.name,
    required this.icon,
    required this.initialAmount,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,
      "name": name,
      "icon": icon,
      "initial_amount": initialAmount,
    };
  }

  factory AccountModel.fromMap(
    Map<String, dynamic> map, {
    double balance = 0.0,
  }) {
    return AccountModel(
      id: map["id"],
      name: map["name"],
      icon: map["icon"] ?? "",
      initialAmount: (map["initial_amount"] ?? 0).toDouble(),
      balance: balance,
    );
  }
}

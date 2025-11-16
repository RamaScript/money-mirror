import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseSeeder {
  static const String _seededKey = "database_seeded";

  /// Checks if data has already been seeded, if not, seeds the database
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool(_seededKey) ?? false;

    if (!alreadySeeded) {
      await _seedDatabase();
      await prefs.setBool(_seededKey, true);
      print("✅ Database seeded successfully!");
    } else {
      print("ℹ️ Database already seeded, skipping...");
    }
  }

  /// Seeds the database with default accounts and categories
  static Future<void> _seedDatabase() async {
    await _seedAccounts();
    await _seedCategories();
  }

  /// Pre-fill default accounts
  static Future<void> _seedAccounts() async {
    final defaultAccounts = [
      {"name": "Bank", "icon": "🏦", "initial_amount": 0.0},
      {"name": "Cash", "icon": "💵", "initial_amount": 0.0},
    ];

    for (var account in defaultAccounts) {
      await AccountDao.insertAccount(account);
    }

    print("✅ Default accounts added: Bank, Cash");
  }

  /// Pre-fill default categories
  static Future<void> _seedCategories() async {
    // Income Categories
    final incomeCategories = [
      {"name": "Salary", "icon": "💰", "type": AppStrings.INCOME},
      {"name": "Freelance", "icon": "💼", "type": AppStrings.INCOME},
      {"name": "Investment", "icon": "📈", "type": AppStrings.INCOME},
      {"name": "Gift", "icon": "🎁", "type": AppStrings.INCOME},
    ];

    // Expense Categories
    final expenseCategories = [
      {"name": "Groceries", "icon": "🛒", "type": AppStrings.EXPENSE},
      {"name": "Fast Food", "icon": "🍔", "type": AppStrings.EXPENSE},
      {"name": "Restaurant", "icon": "🍽️", "type": AppStrings.EXPENSE},
      {"name": "Salon", "icon": "💇", "type": AppStrings.EXPENSE},
      {"name": "Phone Bill", "icon": "📱", "type": AppStrings.EXPENSE},
      {"name": "Internet", "icon": "🌐", "type": AppStrings.EXPENSE},
      {"name": "Electricity", "icon": "💡", "type": AppStrings.EXPENSE},
      {"name": "Transport", "icon": "🚗", "type": AppStrings.EXPENSE},
      {"name": "Fuel", "icon": "⛽", "type": AppStrings.EXPENSE},
      {"name": "Shopping", "icon": "🛍️", "type": AppStrings.EXPENSE},
      {"name": "Entertainment", "icon": "🎬", "type": AppStrings.EXPENSE},
      {"name": "Health", "icon": "🏥", "type": AppStrings.EXPENSE},
      {"name": "Education", "icon": "📚", "type": AppStrings.EXPENSE},
      {"name": "Rent", "icon": "🏠", "type": AppStrings.EXPENSE},
      {"name": "Other", "icon": "💸", "type": AppStrings.EXPENSE},
    ];

    // Insert Income Categories
    for (var category in incomeCategories) {
      await CategoryDao.insertCategory(category);
    }

    // Insert Expense Categories
    for (var category in expenseCategories) {
      await CategoryDao.insertCategory(category);
    }

    print(
      "✅ Default categories added: ${incomeCategories.length} income, ${expenseCategories.length} expense",
    );
  }

  /// Reset database seeding (useful for testing)
  static Future<void> resetSeeding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seededKey);
    print(
      "⚠️ Database seeding flag reset. Data will be seeded on next app launch.",
    );
  }
}

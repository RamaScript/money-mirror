import 'package:flutter/foundation.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseSeeder {
  static const String _seededKey = "database_seeded";

  static const int transactionCount = 500;
  static final DateTime fromDate = DateTime.now().subtract(Duration(days: 30));
  static final DateTime toDate = DateTime.now();

  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool(_seededKey) ?? false;

    if (!alreadySeeded) {
      await _seedDatabase();
      await prefs.setBool(_seededKey, true);
      appLog("✅ Database seeded successfully!");
    } else {
      appLog("ℹ️ Database already seeded, skipping...");
    }
  }

  static Future<void> _seedDatabase() async {
    await _seedAccounts();
    await _seedCategories();
    // TODO: Remove before production - Demo data for testing
    // await _seedDemoTransactions();
    // await _seedDemoBudgets();
  }

  /// Pre-fill default accounts
  static Future<void> _seedAccounts() async {
    final defaultAccounts = [
      {"name": "Bank", "icon": "🏦", "initial_amount": 0.0},
      {"name": "Cash", "icon": "💵", "initial_amount": 0.0},
      {"name": "SBI", "icon": "🪙", "initial_amount": 0.0},
    ];

    for (var account in defaultAccounts) {
      await AccountDao.insertAccount(account);
    }

    if (kDebugMode) {
      appLog("✅ Default accounts added: Bank, Cash");
    }
  }

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

    for (var category in incomeCategories) {
      await CategoryDao.insertCategory(category);
    }

    for (var category in expenseCategories) {
      await CategoryDao.insertCategory(category);
    }

    appLog(
      "✅ Default categories added: ${incomeCategories.length} income, ${expenseCategories.length} expense",
    );
  }
}

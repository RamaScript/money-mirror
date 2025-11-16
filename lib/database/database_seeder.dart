import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/database/dao/budget_dao.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/database/dao/transaction_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseSeeder {
  static const String _seededKey = "database_seeded";

  static const int transactionCount = 500;
  static final DateTime fromDate = DateTime.now().subtract(Duration(days: 30));
  static final DateTime toDate = DateTime.now();

  /// Checks if data has already been seeded, if not, seeds the database
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

  /// Seeds the database with default data
  static Future<void> _seedDatabase() async {
    await _seedAccounts();
    await _seedCategories();
    // TODO: Remove before production - Demo data for testing
    await _seedDemoTransactions();
    await _seedDemoBudgets();
  }

  /// Pre-fill default accounts
  static Future<void> _seedAccounts() async {
    final defaultAccounts = [
      {"name": "Bank", "icon": "🏦", "initial_amount": 0.0},
      {"name": "Cash", "icon": "💵", "initial_amount": 0.0},
      {"name": "SBI", "icon": "💵", "initial_amount": 0.0},
      {"name": "Card 1", "icon": "💵", "initial_amount": 0.0},
      {"name": "Card 2", "icon": "💵", "initial_amount": 0.0},
      {"name": "Card 3", "icon": "💵", "initial_amount": 0.0},
      {"name": "Card 4", "icon": "💵", "initial_amount": 0.0},
      {"name": "Card 5", "icon": "💵", "initial_amount": 0.0},
      {"name": "Card 6", "icon": "💵", "initial_amount": 0.0},
      {"name": "Card 7", "icon": "💵", "initial_amount": 0.0},
    ];

    for (var account in defaultAccounts) {
      await AccountDao.insertAccount(account);
    }

    if (kDebugMode) {
      appLog("✅ Default accounts added: Bank, Cash");
    }
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

  /// Seeds demo transactions (realistic examples)
  static Future<void> _seedDemoTransactions() async {
    try {
      appLog("💳 [TransactionSeeder] Generating dummy transactions...");

      final accounts = await AccountDao.getAccounts();
      final categories = await CategoryDao.getCategories();

      if (accounts.isEmpty || categories.isEmpty) {
        appLog("⚠️ No accounts or categories found. Skipping transactions.");
        return;
      }

      final random = Random();
      int inserted = 0;

      for (int i = 0; i < transactionCount; i++) {
        // Pick random account
        final account = accounts[random.nextInt(accounts.length)];

        // Pick random category
        final category = categories[random.nextInt(categories.length)];

        final bool isIncome = category['type'] == AppStrings.INCOME;

        // Random date in range
        final totalDays = toDate.difference(fromDate).inDays;
        final randomDate = fromDate.add(
          Duration(
            days: random.nextInt(totalDays + 1),
            hours: random.nextInt(24),
            minutes: random.nextInt(60),
          ),
        );

        // Amount range (income gets higher values)
        final amount = isIncome
            ? (500 + random.nextInt(40000)) * 1.0
            : (20 + random.nextInt(5000)) * 1.0;

        final transaction = {
          "amount": amount,
          "type": isIncome ? AppStrings.INCOME : AppStrings.EXPENSE,
          "account_id": account['id'],
          "category_id": category['id'],
          "date": randomDate.toIso8601String(),
          "note": null,
        };

        try {
          await TransactionDao.insertTransaction(transaction);
          inserted++;
        } catch (e) {
          appLog("⚠️ Error inserting transaction: $e");
        }
      }

      appLog("✅ Dummy transactions inserted: $inserted/$transactionCount");
    } catch (e) {
      appLog("⚠️ Error seeding dummy transactions: $e");
    }
  }

  /// Seeds demo budgets (realistic monthly budgets)
  static Future<void> _seedDemoBudgets() async {
    try {
      appLog("💰 [BudgetSeeder] Starting demo budget seeding...");

      final categories = await CategoryDao.getCategories(
        type: AppStrings.EXPENSE,
      );

      if (categories.isEmpty) {
        appLog(
          "⚠️ [BudgetSeeder] No expense categories found. Skipping budgets.",
        );
        return;
      }

      // Helper function to get category ID by name
      int getCategoryId(String categoryName) {
        final category = categories.firstWhere(
          (c) => c['name'] == categoryName,
          orElse: () => categories.first,
        );
        return category['id'] as int;
      }

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Demo budgets for current month (realistic monthly limits)
      final demoBudgets = [
        {
          "category_id": getCategoryId("Rent"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 15000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Groceries"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 5000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Fast Food"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 2000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Restaurant"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 3000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Transport"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 3000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Fuel"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 3000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Electricity"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 1500.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Internet"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 1000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Phone Bill"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 600.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Shopping"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 4000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Entertainment"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 2000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Health"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 2000.0,
          "type": AppStrings.EXPENSE,
        },
        {
          "category_id": getCategoryId("Salon"),
          "month": currentMonth,
          "year": currentYear,
          "amount": 1000.0,
          "type": AppStrings.EXPENSE,
        },
      ];

      // Insert all budgets
      int inserted = 0;
      for (var budget in demoBudgets) {
        try {
          // Check if budget already exists
          final exists = await BudgetDao.budgetExists(
            categoryId: budget['category_id'] as int,
            month: budget['month'] as int,
            year: budget['year'] as int,
          );

          if (!exists) {
            await BudgetDao.insertBudget(budget);
            inserted++;
          }
        } catch (e) {
          appLog("⚠️ [BudgetSeeder] Error inserting budget: $e");
        }
      }

      appLog(
        "✅ [BudgetSeeder] Demo budgets added: $inserted/${demoBudgets.length}",
      );
    } catch (e, stackTrace) {
      appLog("⚠️ [BudgetSeeder] Error seeding demo budgets: $e");
      appLog("⚠️ [BudgetSeeder] Stack trace: $stackTrace");
    }
  }

  /// Reset database seeding (useful for testing)
  static Future<void> resetSeeding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seededKey);
    appLog(
      "⚠️ Database seeding flag reset. Data will be seeded on next app launch.",
    );
  }
}

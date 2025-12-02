import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/models/category_model.dart';
import 'package:money_mirror/views/widgets/category/category_dialog.dart';
import 'package:money_mirror/views/widgets/category/category_transactions_bottom_sheet.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> incomeCategories = [];
  List<CategoryModel> expenseCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    setState(() => isLoading = true);

    final incomeData = await CategoryDao.getCategories(type: AppStrings.INCOME);
    final expenseData = await CategoryDao.getCategories(
      type: AppStrings.EXPENSE,
    );

    setState(() {
      expenseCategories = expenseData
          .map((e) => CategoryModel.fromMap(e))
          .toList();
      incomeCategories = incomeData
          .map((e) => CategoryModel.fromMap(e))
          .toList();
      isLoading = false;
    });
  }

  void _refreshCategories() {
    loadCategories();
  }

  void _openAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(onSaved: _refreshCategories),
    );
  }

  void _openEditCategoryDialog({required CategoryModel category}) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: category, // Pass the category to enable edit mode
        onSaved: _refreshCategories,
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text("Are you sure you want to delete ${category.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CategoryDao.deleteCategory(category.id!);
      loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Categories",
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: SvgPicture.asset(
            ImagePaths.icMenu,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openAddCategoryDialog,
            icon: SvgPicture.asset(
              ImagePaths.icAdd,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadCategories,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (incomeCategories.isNotEmpty)
                      _buildCategorySection(
                        theme: theme,
                        title: "Income categories",
                        items: incomeCategories,
                      ),
                    if (expenseCategories.isNotEmpty)
                      _buildCategorySection(
                        theme: theme,
                        title: "Expense categories",
                        items: expenseCategories,
                      ),
                    if (incomeCategories.isEmpty && expenseCategories.isEmpty)
                      Center(child: _buildEmptyState(theme)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategorySection({
    required ThemeData theme,
    required String title,
    required List<CategoryModel> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16,
            bottom: 4,
            top: 16,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        Divider(),

        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          return _buildCategoryCard(cat, index + 1, theme);
        }),
      ],
    );
  }

  Widget _buildCategoryCard(
    CategoryModel category,
    int index,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCategoryTransactions(category),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ),

                // Menu
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == "edit") {
                      _openEditCategoryDialog(category: category);
                    } else if (value == "delete") {
                      _deleteCategory(category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Edit"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Delete"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            ImagePaths.icCategory,
            color: Theme.of(context).colorScheme.primary,
            height: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "No categories added",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to add your first category",
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryTransactions(CategoryModel category) {
    CategoryTransactionsBottomSheet.show(
      context,
      category,
      onTransactionUpdated: loadCategories,
    );
  }
}

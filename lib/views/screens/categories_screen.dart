import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/ui_utils.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/models/category_model.dart';
import 'package:money_mirror/views/widgets/category/create_category_dialog.dart';
import 'package:money_mirror/views/widgets/category/edit_category_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> incomeCategories = [];
  List<CategoryModel> expenseCategories = [];

  Future<void> loadCategories() async {
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
    });
  }

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void _openAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateCategoryDialog(
        onAdded: () {
          loadCategories();
        },
      ),
    );
  }

  void _openEditCategoryDialog({required CategoryModel category}) {
    showDialog(
      context: context,
      builder: (_) => EditCategoryDialog(
        onAdded: () {
          loadCategories();
        },
        category: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Categories"),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: Icon(Icons.menu),
        ),
        actions: [
          IconButton(onPressed: _openAddCategoryDialog, icon: Icon(Icons.add)),
        ],
      ),
      body: incomeCategories.isEmpty && expenseCategories.isEmpty
          ? Center(child: Text("No categories added"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (incomeCategories.isNotEmpty)
                    _buildCategorySection(
                      title: "Income Category",
                      items: incomeCategories,
                    ),
                  if (expenseCategories.isNotEmpty)
                    _buildCategorySection(
                      title: "Expense Categories",
                      items: expenseCategories,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<CategoryModel> items,
  }) {
    return Column(
      children: [
        UiUtils.buildListHeader(title: title),
        ListView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final cat = items[index];
            return ListTile(
              leading: Text(cat.icon, style: TextStyle(fontSize: 32)),
              title: Text(cat.name),
              trailing: PopupMenuButton(
                icon: Icon(Icons.more_horiz),
                onSelected: (v) {
                  if (v == "edit") {
                    _openEditCategoryDialog(category: cat);
                  } else if (v == "delete") {
                    CategoryDao.deleteCategory(cat.id!);
                    loadCategories();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text("Delete"),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

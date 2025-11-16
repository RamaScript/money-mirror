import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/budget_dao.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/models/budget_model.dart';
import 'package:money_mirror/models/category_model.dart';
import 'package:money_mirror/views/widgets/custom_text_field.dart';

class CreateBudgetDialog extends StatefulWidget {
  final VoidCallback onAdded;
  final int? preSelectedMonth;
  final int? preSelectedYear;

  const CreateBudgetDialog({
    super.key,
    required this.onAdded,
    this.preSelectedMonth,
    this.preSelectedYear,
  });

  @override
  State<CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<CreateBudgetDialog> {
  final amountCtrl = TextEditingController();

  List<CategoryModel> categories = [];
  CategoryModel? selectedCategory;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedMonth != null) {
      selectedMonth = widget.preSelectedMonth!;
    }
    if (widget.preSelectedYear != null) {
      selectedYear = widget.preSelectedYear!;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final expenseData = await CategoryDao.getCategories(
      type: AppStrings.EXPENSE,
    );
    setState(() {
      categories = expenseData.map((e) => CategoryModel.fromMap(e)).toList();
      isLoading = false;
    });
  }

  Future<void> _save() async {
    // Validation
    if (selectedCategory == null) {
      SnackUtils.error(context, "Please select a category ");
      return;
    }

    if (amountCtrl.text.trim().isEmpty) {
      SnackUtils.error(context, "Please enter budget amount ");
      return;
    }

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      SnackUtils.error(context, "Please enter a valid positive amount ");
      return;
    }

    if (amount > 10000000) {
      SnackUtils.error(context, "Amount seems unrealistic. Please check. ");
      return;
    }

    // Check if budget already exists
    final exists = await BudgetDao.budgetExists(
      categoryId: selectedCategory!.id!,
      month: selectedMonth,
      year: selectedYear,
    );

    if (exists) {
      SnackUtils.error(
        context,
        "Budget already exists for this category and month ",
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final budget = BudgetModel(
        categoryId: selectedCategory!.id!,
        month: selectedMonth,
        year: selectedYear,
        amount: amount,
        type: AppStrings.EXPENSE,
      );

      await BudgetDao.insertBudget(budget.toMap());
      widget.onAdded();
      if (mounted) {
        Navigator.pop(context);
        SnackUtils.success(context, "Budget created successfully ");
      }
    } catch (e) {
      if (mounted) {
        SnackUtils.error(context, "Failed to create budget: $e ");
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 18),
      contentPadding: EdgeInsets.all(20),
      content: isLoading
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Create Budget ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(color: AppColors.primaryColor),
                  SizedBox(height: 8),

                  // Category Selector
                  Text(
                    "Category ",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CategoryModel>(
                        isExpanded: true,
                        hint: Text("Select Category "),
                        value: selectedCategory,
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Text(cat.icon, style: TextStyle(fontSize: 24)),
                                SizedBox(width: 12),
                                Text(cat.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedCategory = value);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Month Selector
                  Text(
                    "Month & Year ",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: selectedMonth,
                              items: List.generate(12, (index) {
                                final month = index + 1;
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(_getMonthName(month)),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedMonth = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: selectedYear,
                              items: List.generate(5, (index) {
                                final year = DateTime.now().year - 1 + index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedYear = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Amount Input
                  CustomTextField(
                    controller: amountCtrl,
                    label: "Budget Amount ",
                    showTitle: true,
                    titleTextColor: Colors.grey,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey.shade100,
                    inputTextColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    borderColor: AppColors.primaryColor,
                    focusedBorderColor: AppColors.secondryColor,
                    placeHolder: "Enter amount (e.g., 5000) ",
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^ d+ .? d{0,2}'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Set spending limit for ${_getMonthName(selectedMonth)} $selectedYear ",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      actions: isLoading
          ? []
          : [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: Text("Cancel ", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: AppColors.primaryColor,
                  elevation: 4,
                ),
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Create ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }
}

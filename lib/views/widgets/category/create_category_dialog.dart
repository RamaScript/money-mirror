import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/models/category_model.dart';

import '../custom_text_field.dart';

class CreateCategoryDialog extends StatefulWidget {
  final VoidCallback onAdded;

  const CreateCategoryDialog({super.key, required this.onAdded});

  @override
  State<CreateCategoryDialog> createState() => CreateCategoryDialogState();
}

class CreateCategoryDialogState extends State<CreateCategoryDialog> {
  String selectedType = AppStrings.EXPENSE;
  final nameCtrl = TextEditingController();
  final iconCtrl = TextEditingController();

  void _save() async {
    final category = CategoryModel(
      name: nameCtrl.text.trim(),
      icon: iconCtrl.text.trim(),
      type: selectedType,
    );

    await CategoryDao.insertCategory(category.toMap());
    widget.onAdded();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.grey.shade900,
      insetPadding: EdgeInsets.symmetric(horizontal: 18),
      contentPadding: EdgeInsets.all(20),

      content: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Add new category",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(color: AppColors.primaryColor),
            Text(
              "Category Type",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 10),

            buildIconToggle(),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                "Category Details",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),

              child: CustomTextField(
                controller: nameCtrl,
                label: "Name",
                showTitle: false,
                titleTextColor: Colors.white70,
                backgroundColor: Colors.white10,
                inputTextColor: Colors.white,
                borderColor: AppColors.primaryColor,
                focusedBorderColor: AppColors.secondryColor,
                placeHolder: "Enter Category Name",
              ),
            ),

            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: CustomTextField(
                controller: iconCtrl,
                label: "Icon",
                onInvalidInput: () {
                  SnackUtils.info(context, "Only 1 emoji is allowed");
                },

                showTitle: false,
                titleTextColor: Colors.white70,
                backgroundColor: Colors.white10,
                inputTextColor: Colors.white,
                borderColor: AppColors.primaryColor,
                focusedBorderColor: AppColors.secondryColor,
                placeHolder: "Enter Icon",
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(
                      r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}]',
                      unicode: true,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (var e in ["🍔", "🛒", "💵", "🎉", "🚗", "📚"])
                  GestureDetector(
                    onTap: () => iconCtrl.text = e,
                    child: Container(
                      margin: EdgeInsets.only(right: 8, top: 6),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(e, style: TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: AppColors.primaryColor,
            elevation: 4,
          ),
          onPressed: _save,
          child: Text(
            "Save",
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

  Widget buildIconToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _iconPill("💰 Income", AppStrings.INCOME),
        SizedBox(width: 16),
        _iconPill("💸 Expense", AppStrings.EXPENSE),
      ],
    );
  }

  Widget _iconPill(String label, String value) {
    final isSelected = selectedType == value;

    return InkWell(
      onTap: () => setState(() => selectedType = value),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

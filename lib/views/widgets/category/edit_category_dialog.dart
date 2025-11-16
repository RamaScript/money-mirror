import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/models/category_model.dart';

import '../custom_text_field.dart';

class EditCategoryDialog extends StatefulWidget {
  final VoidCallback onAdded;
  final CategoryModel category;

  const EditCategoryDialog({
    super.key,
    required this.onAdded,
    required this.category,
  });

  @override
  State<EditCategoryDialog> createState() => EditCategoryDialogState();
}

class EditCategoryDialogState extends State<EditCategoryDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController iconCtrl;

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(text: widget.category.name);
    iconCtrl = TextEditingController(text: widget.category.icon);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit category"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            CustomTextField(
              controller: nameCtrl,
              label: 'Name',
              placeHolder: widget.category.name,
              titleTextColor: Colors.white70,
              backgroundColor: Colors.white10,
              inputTextColor: Colors.white,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
            ),
            SizedBox(height: 18),
            CustomTextField(
              controller: iconCtrl,
              label: 'Icon',
              placeHolder: 'Icon',
              onInvalidInput: () {
                SnackUtils.info(context, "Only one emoji allowed");
              },
              titleTextColor: Colors.white70,
              backgroundColor: Colors.white10,
              inputTextColor: Colors.white,
              borderColor: AppColors.primaryColor,
              maxLength: 1, // ✔ only one character allowed
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(
                    r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}]',
                    unicode: true,
                  ),
                ),
              ],
              focusedBorderColor: AppColors.secondryColor,
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Close", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => _updateCategory(
            id: widget.category.id!,
            data: {'name': nameCtrl.text, 'icon': iconCtrl.text},
          ),
          child: Text("Save"),
        ),
      ],
    );
  }

  void _updateCategory({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    if (nameCtrl.text.isEmpty || iconCtrl.text.isEmpty) {
      SnackUtils.info(context, "Please fill all fields");
      return;
    }

    await CategoryDao.updateCategory(id: id, data: data);

    widget.onAdded(); // refresh list
    Navigator.pop(context); // close dialog
  }
}

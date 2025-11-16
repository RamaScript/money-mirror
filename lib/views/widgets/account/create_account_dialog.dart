import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/models/account_model.dart';

import '../custom_text_field.dart';

class CreateAccountDialog extends StatefulWidget {
  final VoidCallback onAdded;

  const CreateAccountDialog({super.key, required this.onAdded});

  @override
  State<CreateAccountDialog> createState() => CreateAccountDialogState();
}

class CreateAccountDialogState extends State<CreateAccountDialog> {
  final nameCtrl = TextEditingController();
  final iconCtrl = TextEditingController();
  final initialAmountCtrl = TextEditingController(text: "0");
  bool isSaving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    iconCtrl.dispose();
    initialAmountCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    // Prevent multiple saves
    if (isSaving) return;

    // Validate name
    if (nameCtrl.text.trim().isEmpty) {
      SnackUtils.warning(context, "Name is required");

      return;
    }

    // Validate icon
    if (iconCtrl.text.trim().isEmpty) {
      SnackUtils.warning(context, "Icon is required");

      return;
    }

    setState(() => isSaving = true);

    try {
      final account = AccountModel(
        name: nameCtrl.text.trim(),
        icon: iconCtrl.text.trim(),
        initialAmount: double.tryParse(initialAmountCtrl.text.trim()) ?? 0,
      );

      await AccountDao.insertAccount(account.toMap());

      widget.onAdded();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        SnackUtils.error(context, "Error saving account: $e");
      }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Add new Account",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(color: AppColors.primaryColor),

            SizedBox(height: 8),

            // NAME
            CustomTextField(
              controller: nameCtrl,
              label: "Name",
              showTitle: true,
              titleTextColor: Colors.white70,
              backgroundColor: Colors.white10,
              inputTextColor: Colors.white,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
              placeHolder: "Enter Account Name",
            ),

            SizedBox(height: 18),

            // INITIAL AMOUNT
            CustomTextField(
              controller: initialAmountCtrl,
              label: "Initial Amount",
              showTitle: true,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              titleTextColor: Colors.white70,
              backgroundColor: Colors.white10,
              inputTextColor: Colors.white,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
              placeHolder: "Enter Initial Amount",
            ),

            SizedBox(height: 18),

            // ICON INPUT
            CustomTextField(
              controller: iconCtrl,
              label: "Icon",
              showTitle: true,
              titleTextColor: Colors.white70,
              backgroundColor: Colors.white10,
              inputTextColor: Colors.white,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
              placeHolder: "Select an emoji",
              maxLength: 1,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(
                    r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}]',
                    unicode: true,
                  ),
                ),
              ],
              onInvalidInput: () {
                SnackUtils.warning(context, "Only 1 emoji allowed");
              },
            ),

            SizedBox(height: 8),

            // QUICK EMOJI SELECT ROW
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var e in ["💰", "🏦", "💳", "📦", "👜", "💵"])
                  GestureDetector(
                    onTap: () => setState(() => iconCtrl.text = e),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconCtrl.text == e
                            ? AppColors.primaryColor.withOpacity(0.3)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: iconCtrl.text == e
                              ? AppColors.primaryColor
                              : Colors.white24,
                          width: iconCtrl.text == e ? 2 : 1,
                        ),
                      ),
                      child: Text(e, style: TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),

      // BUTTONS
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  "Save",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ],
    );
  }
}

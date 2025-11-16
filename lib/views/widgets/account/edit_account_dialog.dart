import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/models/account_model.dart';

import '../custom_text_field.dart';

class EditAccountDialog extends StatefulWidget {
  final VoidCallback onAdded;
  final AccountModel account;

  const EditAccountDialog({
    super.key,
    required this.onAdded,
    required this.account,
  });

  @override
  State<EditAccountDialog> createState() => EditAccountDialogState();
}

class EditAccountDialogState extends State<EditAccountDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController iconCtrl;
  late TextEditingController initialAmountCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.account.name);
    iconCtrl = TextEditingController(text: widget.account.icon);
    initialAmountCtrl = TextEditingController(
      text: widget.account.initialAmount.toString(),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    iconCtrl.dispose();
    initialAmountCtrl.dispose();
    super.dispose();
  }

  void _updateAccount() async {
    if (nameCtrl.text.trim().isEmpty) {
      SnackUtils.error(context, "Name is required");
      return;
    }

    if (iconCtrl.text.trim().isEmpty) {
      SnackUtils.error(context, "Icon is required");
      return;
    }

    final data = {
      'name': nameCtrl.text.trim(),
      'icon': iconCtrl.text.trim(),
      'initial_amount': double.tryParse(initialAmountCtrl.text.trim()) ?? 0,
    };

    await AccountDao.updateAccount(id: widget.account.id!, data: data);

    widget.onAdded(); // refresh list
    if (mounted) Navigator.pop(context); // close dialog
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 18),
      contentPadding: EdgeInsets.all(20),

      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                AppStrings.EDIT_ACCOUNT,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            Divider(color: AppColors.primaryColor),

            // INITIAL AMOUNT
            CustomTextField(
              controller: initialAmountCtrl,
              label: AppStrings.INITIAL_AMOUNT,
              showTitle: false,
              keyboardType: TextInputType.number,
              titleTextColor: theme.textTheme.bodyMedium?.color,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade100,
              inputTextColor: theme.textTheme.bodyLarge?.color,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
              placeHolder: "Enter Initial Amount",
            ),

            SizedBox(height: 18),

            // NAME
            CustomTextField(
              controller: nameCtrl,
              label: AppStrings.NAME,
              showTitle: false,
              titleTextColor: theme.textTheme.bodyMedium?.color,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade100,
              inputTextColor: theme.textTheme.bodyLarge?.color,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
              placeHolder: "Enter Account Name",
            ),

            SizedBox(height: 18),

            // ICON INPUT
            CustomTextField(
              controller: iconCtrl,
              label: AppStrings.ICON,
              showTitle: false,
              titleTextColor: theme.textTheme.bodyMedium?.color,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade100,
              inputTextColor: theme.textTheme.bodyLarge?.color,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
              placeHolder: "Enter Icon",
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
                SnackUtils.info(context, "Only 1 emoji allowed");
              },
            ),

            SizedBox(height: 8),

            // QUICK EMOJI SELECT ROW
            Row(
              children: [
                for (var e in ["💰", "🏦", "💳", "📦", "👜", "💵"])
                  GestureDetector(
                    onTap: () => iconCtrl.text = e,
                    child: Container(
                      margin: EdgeInsets.only(right: 8, top: 6),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppStrings.CANCEL,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _updateAccount,
          child: Text(
            AppStrings.SAVE,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

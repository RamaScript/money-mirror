import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/budget_dao.dart';
import 'package:money_mirror/views/widgets/custom_text_field.dart';

class EditBudgetDialog extends StatefulWidget {
  final Map<String, dynamic> budget;
  final VoidCallback onUpdated;

  const EditBudgetDialog({
    super.key,
    required this.budget,
    required this.onUpdated,
  });

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  late TextEditingController amountCtrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentAmount = (widget.budget['amount'] as num).toDouble();
    amountCtrl = TextEditingController(text: currentAmount.toStringAsFixed(2));
  }

  Future<void> _save() async {
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

    setState(() => isSaving = true);

    try {
      await BudgetDao.updateBudget(
        id: widget.budget['id'],
        data: {'amount': amount},
      );

      widget.onUpdated();
      if (mounted) {
        Navigator.pop(context);
        SnackUtils.success(context, "Budget updated successfully ");
      }
    } catch (e) {
      if (mounted) {
        SnackUtils.error(context, "Failed to update budget: \$e ");
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.budget['category_name'] ?? 'Unknown';
    final categoryIcon = widget.budget['category_icon'] ?? '💰';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.grey900
          : AppColors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 18),
      contentPadding: EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Edit Budget ",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(color: AppColors.primaryColor),
            SizedBox(height: 16),

            // Category Display
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Row(
                children: [
                  Text(categoryIcon, style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Text(
                    categoryName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Amount Input
            CustomTextField(
              controller: amountCtrl,
              label: "Budget Amount ",
              showTitle: true,
              titleTextColor: AppColors.grey,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.white10
                  : AppColors.grey100,
              inputTextColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.white
                  : AppColors.black87,
              borderColor: AppColors.primaryColor,
              focusedBorderColor: AppColors.secondryColor,
              placeHolder: "Enter amount ",
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: Text("Cancel ", style: TextStyle(color: AppColors.grey)),
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
                    color: AppColors.white,
                  ),
                )
              : Text(
                  "Update ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }
}

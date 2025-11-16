import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/budget_dao.dart';
import 'package:money_mirror/models/budget_model.dart';

class SetBudgetDialog extends StatefulWidget {
  final Map<String, dynamic> category;
  final int month;
  final int year;
  final VoidCallback onBudgetSet;

  const SetBudgetDialog({
    super.key,
    required this.category,
    required this.month,
    required this.year,
    required this.onBudgetSet,
  });

  @override
  State<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<SetBudgetDialog> {
  final amountCtrl = TextEditingController();
  bool isSaving = false;
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadExistingBudget();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingBudget() async {
    try {
      final existing = await BudgetDao.getBudgetForCategory(
        categoryId: widget.category['id'],
        month: widget.month,
        year: widget.year,
      );

      if (existing != null && mounted) {
        final amount = (existing['amount'] as num).toDouble();
        amountCtrl.text = amount.toStringAsFixed(2);
        appLog(
          "💰 [SetBudgetDialog] Loaded existing budget: ${amount.toStringAsFixed(2)}",
        );
      }
    } catch (e) {
      appLog("⚠️ [SetBudgetDialog] Error loading existing budget: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      SnackUtils.error(context, "Please enter a valid positive amount");
      return;
    }

    if (amount > 10000000) {
      SnackUtils.error(context, "Amount seems unrealistic. Please check.");
      return;
    }

    // Check if budget already exists
    final exists = await BudgetDao.budgetExists(
      categoryId: widget.category['id'],
      month: widget.month,
      year: widget.year,
    );

    if (exists) {
      final existing = await BudgetDao.getBudgetForCategory(
        categoryId: widget.category['id'],
        month: widget.month,
        year: widget.year,
      );

      if (existing != null) {
        // Update existing budget
        setState(() => isSaving = true);
        try {
          await BudgetDao.updateBudget(
            id: existing['id'],
            data: {'amount': amount},
          );
          widget.onBudgetSet();
          if (mounted) {
            Navigator.pop(context);
            SnackUtils.success(context, "Budget updated successfully");
          }
        } catch (e) {
          if (mounted) {
            SnackUtils.error(context, "Failed to update budget: $e");
          }
        } finally {
          if (mounted) {
            setState(() => isSaving = false);
          }
        }
        return;
      }
    }

    setState(() => isSaving = true);

    try {
      final budget = BudgetModel(
        categoryId: widget.category['id'],
        month: widget.month,
        year: widget.year,
        amount: amount,
        type: AppStrings.EXPENSE,
      );

      await BudgetDao.insertBudget(budget.toMap());
      widget.onBudgetSet();
      if (mounted) {
        Navigator.pop(context);
        SnackUtils.success(context, "Budget set successfully");
      }
    } catch (e) {
      if (mounted) {
        SnackUtils.error(context, "Failed to set budget: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthName = DateFormat(
      'MMMM, yyyy',
    ).format(DateTime(widget.year, widget.month));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Set budget",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 24),

              // Category Display
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.category['icon'] ?? '💰',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.category['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Limit Input Field
              Text(
                "Limit",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              isLoading
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter amount",
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        prefixText: PrefCurrencySymbol.rupee,
                        prefixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter budget amount";
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return "Please enter a valid positive amount";
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),

              // Month Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Month: $monthName",
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      "CANCEL",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving ? null : _save,
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "SET",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

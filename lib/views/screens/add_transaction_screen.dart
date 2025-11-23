import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/database/dao/transaction_dao.dart';
import 'package:money_mirror/models/account_model.dart';
import 'package:money_mirror/models/category_model.dart';
import 'package:money_mirror/models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final noteCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  String selectedType = AppStrings.EXPENSE;
  AccountModel? selectedAccount;
  AccountModel? selectedToAccount; // For transfers
  CategoryModel? selectedCategory;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  List<AccountModel> accounts = [];
  List<CategoryModel> categories = [];

  bool isSaving = false;
  int? editingTransactionId;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _initializeEditMode();
    } else {
      selectedTime = TimeOfDay.fromDateTime(selectedDate);
    }
    loadAccounts();
    loadCategories();
  }

  void _initializeEditMode() {
    final transaction = widget.transactionToEdit!;
    editingTransactionId = transaction['id'] as int?;
    selectedType = transaction['type'] as String;
    amountCtrl.text = (transaction['amount'] as num).toStringAsFixed(2);
    noteCtrl.text = transaction['note']?.toString() ?? '';

    final date = DateTime.parse(transaction['date']);
    selectedDate = date;
    selectedTime = TimeOfDay.fromDateTime(date);

    // Will be set after accounts/categories load
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> loadAccounts() async {
    final data = await AccountDao.getAccounts();
    setState(() {
      accounts = data.map((e) => AccountModel.fromMap(e)).toList();
      if (widget.transactionToEdit != null) {
        // Set selected account from transaction being edited
        final accountId = widget.transactionToEdit!['account_id'] as int;
        selectedAccount = accounts.firstWhere(
          (a) => a.id == accountId,
          orElse: () => accounts.first,
        );
      } else if (accounts.isNotEmpty && selectedAccount == null) {
        selectedAccount = accounts.first;
        if (accounts.length > 1) {
          selectedToAccount = accounts[1];
        }
      }
    });
  }

  Future<void> loadCategories() async {
    if (selectedType == AppStrings.TRANSFER) {
      setState(() {
        categories = [];
        selectedCategory = null;
      });
      return;
    }

    final data = await CategoryDao.getCategories(type: selectedType);
    setState(() {
      categories = data.map((e) => CategoryModel.fromMap(e)).toList();
      if (widget.transactionToEdit != null &&
          selectedType != AppStrings.TRANSFER) {
        // Set selected category from transaction being edited
        final categoryId = widget.transactionToEdit!['category_id'] as int;
        if (categoryId > 0) {
          selectedCategory = categories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => categories.isNotEmpty ? categories.first : null!,
          );
        }
      } else {
        selectedCategory = categories.isNotEmpty ? categories.first : null;
      }
    });
  }

  void _changeType(String type) {
    setState(() {
      selectedType = type;
      selectedCategory = null;
    });
    loadCategories();
  }

  Future<void> _selectDate() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primaryColor,
                    surface: Colors.grey.shade900,
                  )
                : ColorScheme.light(
                    primary: AppColors.primaryColor,
                    surface: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
    }
  }

  Future<void> _selectTime() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primaryColor,
                    surface: Colors.grey.shade900,
                  )
                : ColorScheme.light(
                    primary: AppColors.primaryColor,
                    surface: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() => selectedTime = pickedTime);
    }
  }

  Future<void> _saveTransaction() async {
    double parsedAmount = double.tryParse(amountCtrl.text) ?? 0;

    if (parsedAmount <= 0) {
      SnackUtils.error(context, "Please enter a valid amount");
      return;
    }

    if (selectedAccount == null) {
      SnackUtils.error(context, "Please select an account");
      return;
    }

    // For TRANSFER, check to account and create two transactions
    // For TRANSFER - save as single transaction with to_account_id
    if (selectedType == AppStrings.TRANSFER) {
      if (selectedToAccount == null) {
        SnackUtils.error(context, "Please select a destination account");
        return;
      }

      if (selectedAccount!.id == selectedToAccount!.id) {
        SnackUtils.error(context, "Cannot transfer to the same account");
        return;
      }

      setState(() => isSaving = true);

      try {
        // Create single transfer transaction
        final transaction = TransactionModel(
          amount: parsedAmount,
          type: AppStrings.TRANSFER,
          accountId: selectedAccount!.id!,
          toAccountId: selectedToAccount!.id!, // NEW: Destination account
          categoryId: 0,
          date: DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          ).toIso8601String(),
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        );

        if (editingTransactionId != null) {
          await TransactionDao.updateTransaction(
            id: editingTransactionId!,
            data: transaction.toMap(),
          );
          if (mounted) {
            SnackUtils.success(context, "Transfer updated successfully");
            Navigator.pop(context, true);
          }
        } else {
          await TransactionDao.insertTransaction(transaction.toMap());
          if (mounted) {
            SnackUtils.success(context, "Transfer completed successfully");
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        setState(() => isSaving = false);
        SnackUtils.error(context, "Error completing transfer: $e");
      }
      return;
    }
    // For INCOME/EXPENSE
    if (selectedCategory == null) {
      SnackUtils.error(context, "Please select a category");
      return;
    }

    setState(() => isSaving = true);

    try {
      final transaction = TransactionModel(
        amount: parsedAmount,
        type: selectedType,
        accountId: selectedAccount!.id!,
        categoryId: selectedCategory!.id!,
        date: selectedDate.toIso8601String(),
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );

      if (editingTransactionId != null) {
        // Update existing transaction
        await TransactionDao.updateTransaction(
          id: editingTransactionId!,
          data: transaction.toMap(),
        );
        if (mounted) {
          SnackUtils.success(context, "Transaction updated successfully");
          Navigator.pop(context, true);
        }
      } else {
        // Insert new transaction
        await TransactionDao.insertTransaction(transaction.toMap());
        if (mounted) {
          SnackUtils.success(context, "Transaction added successfully");
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
      SnackUtils.error(context, "Error saving transaction: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          editingTransactionId != null
              ? "Edit Transaction"
              : AppStrings.ADD_TRANSACTION,
        ),
      ),
      body: accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.NO_ACCOUNTS_FOUND,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type selector
                  _buildTypeSelector(),

                  SizedBox(height: 20),

                  // Account and Category/To Account selectors
                  Row(
                    children: [
                      Expanded(child: _buildAccountSelector()),
                      SizedBox(width: 12),
                      Expanded(
                        child: selectedType == AppStrings.TRANSFER
                            ? _buildToAccountSelector()
                            : _buildCategorySelector(),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Amount field
                  _buildAmountField(),

                  SizedBox(height: 20),

                  // Notes field
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      return TextField(
                        controller: noteCtrl,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.ADD_NOTES,
                          hintStyle: TextStyle(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white10
                              : Colors.grey.shade100,
                          contentPadding: EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 20),

                  // Date and Time
                  _buildDateTimeRow(),

                  SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSaving ? null : _saveTransaction,
                      child: isSaving
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Save Transaction",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _buildTypeChip("INCOME", AppStrings.INCOME)),
        SizedBox(width: 8),
        Expanded(child: _buildTypeChip("EXPENSE", AppStrings.EXPENSE)),
        SizedBox(width: 8),
        Expanded(child: _buildTypeChip("TRANSFER", AppStrings.TRANSFER)),
      ],
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = selectedType == value;
    return GestureDetector(
      onTap: () => _changeType(value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 16),
            if (isSelected) SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showAccountPicker(),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.ACCOUNT,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Text(
                  selectedAccount?.icon ?? "📁",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedAccount?.name ?? "Account",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToAccountSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showToAccountPicker(),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.TO_ACCOUNT,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Text(
                  selectedToAccount?.icon ?? "📁",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedToAccount?.name ?? "Account",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (categories.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.CATEGORY,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
            SizedBox(height: 6),
            Text(
              AppStrings.NO_CATEGORIES,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showCategoryPicker(),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.CATEGORY,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Text(
                  selectedCategory?.icon ?? "🏷️",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedCategory?.name ?? AppStrings.CATEGORY,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.AMOUNT,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: "0.00",
            hintStyle: TextStyle(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              fontSize: 24,
            ),
            prefixText: PrefCurrencySymbol.rupee,
            prefixStyle: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
            contentPadding: EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.DATE,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${_getMonthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.TIME,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _showAccountPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.SELECT_ACCOUNT,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      leading: Text(
                        account.icon,
                        style: TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        account.name,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      trailing: selectedAccount?.id == account.id
                          ? Icon(Icons.check, color: AppColors.primaryColor)
                          : null,
                      onTap: () {
                        setState(() => selectedAccount = account);
                        Navigator.pop(context, true);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToAccountPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.SELECT_DESTINATION_ACCOUNT,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      leading: Text(
                        account.icon,
                        style: TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        account.name,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      trailing: selectedToAccount?.id == account.id
                          ? Icon(Icons.check, color: AppColors.primaryColor)
                          : null,
                      onTap: () {
                        setState(() => selectedToAccount = account);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.SELECT_CATEGORY,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      leading: Text(
                        category.icon,
                        style: TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        category.name,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      trailing: selectedCategory?.id == category.id
                          ? Icon(Icons.check, color: AppColors.primaryColor)
                          : null,
                      onTap: () {
                        setState(() => selectedCategory = category);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

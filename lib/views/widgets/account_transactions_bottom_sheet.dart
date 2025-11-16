import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/app_strings.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/core/utils/snack_utils.dart';
import 'package:money_mirror/database/dao/transaction_dao.dart';
import 'package:money_mirror/models/account_model.dart';
import 'package:money_mirror/views/screens/add_transaction_screen.dart';
import 'package:money_mirror/views/widgets/date_header.dart';
import 'package:money_mirror/views/widgets/transaction_card.dart';

class AccountTransactionsBottomSheet extends StatelessWidget {
  final AccountModel account;
  final VoidCallback? onTransactionUpdated;

  const AccountTransactionsBottomSheet({
    super.key,
    required this.account,
    this.onTransactionUpdated,
  });

  static Future<void> show(
    BuildContext context,
    AccountModel account, {
    VoidCallback? onTransactionUpdated,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => AccountTransactionsBottomSheet(
        account: account,
        onTransactionUpdated: onTransactionUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        account.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            FutureBuilder<int>(
                              future: _getTransactionCount(),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text(
                                  "$count transaction${count != 1 ? 's' : ''}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.textTheme.bodyLarge?.color),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Transactions list
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Error loading transactions",
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final transactions = snapshot.data ?? [];
                  
                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No transactions",
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by date
                  final grouped = <DateTime, List<Map<String, dynamic>>>{};
                  for (var transaction in transactions) {
                    try {
                      final date = DateTime.parse(transaction['date'].toString());
                      final dateOnly = DateTime(date.year, date.month, date.day);
                      if (!grouped.containsKey(dateOnly)) {
                        grouped[dateOnly] = [];
                      }
                      grouped[dateOnly]!.add(transaction);
                    } catch (e) {
                      // Skip invalid dates
                    }
                  }

                  final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                  final sortedGrouped = <DateTime, List<Map<String, dynamic>>>{};
                  for (var date in sortedDates) {
                    sortedGrouped[date] = grouped[date]!;
                  }

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      ...sortedGrouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateHeader(date: entry.key),
                            ...entry.value.map((transaction) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: TransactionCard(
                                  transaction: transaction,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showTransactionDetails(context, transaction);
                                  },
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadTransactions() async {
    final allTransactions = await TransactionDao.getAllTransactions();
    return allTransactions
        .where((t) => (t['account_id'] as int?) == account.id)
        .toList();
  }

  Future<int> _getTransactionCount() async {
    final transactions = await _loadTransactions();
    return transactions.length;
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> transaction) {
    final theme = Theme.of(context);
    final isIncome = transaction['type'] == AppStrings.INCOME;
    final isTransfer = transaction['type'] == AppStrings.TRANSFER;
    final amount = (transaction['amount'] as num).toDouble();
    final date = DateTime.parse(transaction['date'].toString());
    
    Color typeColor;
    String typeLabel;
    if (isTransfer) {
      typeColor = AppColors.transferColor;
      typeLabel = AppStrings.TRANSFER_LABEL;
    } else if (isIncome) {
      typeColor = AppColors.incomeColor;
      typeLabel = AppStrings.INCOME_LABEL;
    } else {
      typeColor = AppColors.expenseColor;
      typeLabel = AppStrings.EXPENSE_LABEL;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.textTheme.bodyLarge?.color),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTransactionScreen(
                                transactionToEdit: transaction,
                              ),
                            ),
                          );
                          if (result == true) {
                            onTransactionUpdated?.call();
                          }
                        },
                        icon: Icon(Icons.edit, color: AppColors.primaryColor),
                        tooltip: AppStrings.EDIT,
                      ),
                      IconButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await TransactionDao.deleteTransaction(transaction['id']);
                          onTransactionUpdated?.call();
                          if (context.mounted) {
                            SnackUtils.error(context, "Transaction deleted");
                          }
                        },
                        icon: Icon(Icons.delete, color: AppColors.expenseColor),
                        tooltip: AppStrings.DELETE,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: typeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "${PrefCurrencySymbol.rupee}${amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(theme, "Date & Time", DateFormat('MMM dd, yyyy • hh:mm a').format(date)),
                    const SizedBox(height: 16),
                    _buildDetailRow(theme, "Account", transaction['account_name']?.toString() ?? 'Unknown'),
                    const SizedBox(height: 16),
                    if (transaction['category_name'] != null)
                      _buildDetailRow(theme, "Category", transaction['category_name'].toString()),
                    if (transaction['note'] != null && transaction['note'].toString().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        "Note",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transaction['note'].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}


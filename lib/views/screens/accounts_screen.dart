import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/database/dao/transaction_dao.dart';
import 'package:money_mirror/models/account_model.dart';
import 'package:money_mirror/views/widgets/account/create_account_dialog.dart';
import 'package:money_mirror/views/widgets/account/edit_account_dialog.dart';
import 'package:money_mirror/views/widgets/account_transactions_bottom_sheet.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<AccountModel> accounts = [];
  double totalBalance = 0.0;
  double totalExpense = 0.0;
  double totalIncome = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    setState(() => isLoading = true);

    final accountData = await AccountDao.getAccounts();
    
    // Calculate totals
    double balance = 0.0;
    for (var account in accountData) {
      balance += (account['initial_amount'] as num).toDouble();
    }

    // Get transaction totals
    final expense = await TransactionDao.getTotalExpense();
    final income = await TransactionDao.getTotalIncome();

    setState(() {
      accounts = accountData.map((e) => AccountModel.fromMap(e)).toList();
      totalBalance = balance - expense + income;
      totalExpense = expense;
      totalIncome = income;
      isLoading = false;
    });
  }

  void _openAddAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateAccountDialog(
        onAdded: () {
          loadAccounts();
        },
      ),
    );
  }

  void _openEditAccountDialog({required AccountModel account}) {
    showDialog(
      context: context,
      builder: (_) => EditAccountDialog(
        onAdded: () {
          loadAccounts();
        },
        account: account,
      ),
    );
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text(
          "Are you sure you want to delete ${account.name}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AccountDao.deleteAccount(account.id!);
      loadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accounts"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            onPressed: _openAddAccountDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : RefreshIndicator(
              onRefresh: loadAccounts,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Summary Section
                    _buildSummarySection(theme, isDark),

                    const SizedBox(height: 16),

                    // Accounts List
                    if (accounts.isEmpty)
                      _buildEmptyState(theme)
                    else
                      _buildAccountsList(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "[ All Accounts ${totalBalance >= 0 ? '' : '-'}${PrefCurrencySymbol.rupee}${totalBalance.abs().toStringAsFixed(2)} ]",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  "EXPENSE SO FAR",
                  PrefCurrencySymbol.rupee + totalExpense.toStringAsFixed(2),
                  Colors.red.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  "INCOME SO FAR",
                  PrefCurrencySymbol.rupee + totalIncome.toStringAsFixed(2),
                  Colors.green.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Accounts",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        ...accounts.asMap().entries.map((entry) {
          final index = entry.key;
          final account = entry.value;
          return _buildAccountCard(account, index + 1, theme);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAccountCard(
    AccountModel account,
    int index,
    ThemeData theme,
  ) {
    final balance = account.initialAmount;
    final isNegative = balance < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountTransactions(account),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      account.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$index. ${account.name}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Initial: ${PrefCurrencySymbol.rupee}${account.initialAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Balance
                Text(
                  "${isNegative ? '-' : ''}${PrefCurrencySymbol.rupee}${balance.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNegative ? Colors.red : Colors.green,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Menu
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == "edit") {
                      _openEditAccountDialog(account: account);
                    } else if (value == "delete") {
                      _deleteAccount(account);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Edit"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Delete"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            "No accounts added",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to add your first account",
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountTransactions(AccountModel account) {
    AccountTransactionsBottomSheet.show(
      context,
      account,
      onTransactionUpdated: loadAccounts,
    );
  }
}

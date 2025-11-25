import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/database/dao/transaction_dao.dart';
import 'package:money_mirror/models/account_model.dart';
import 'package:money_mirror/views/widgets/account/account_transactions_bottom_sheet.dart';
import 'package:money_mirror/views/widgets/account/create_account_dialog.dart';
import 'package:money_mirror/views/widgets/account/edit_account_dialog.dart';

/// ---------- STATE MODEL (KEPT IN SAME FILE) ----------

class AccountsState {
  final List<AccountModel> accounts;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final Map<int, double> balances;

  const AccountsState({
    required this.accounts,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.balances,
  });

  factory AccountsState.empty() => const AccountsState(
    accounts: [],
    totalIncome: 0,
    totalExpense: 0,
    totalBalance: 0,
    balances: {},
  );
}

/// ---------- MAIN SCREEN ----------

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  AccountsState state = AccountsState.empty();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    setState(() => isLoading = true);

    final accountData = await AccountDao.getAccounts();
    final expensesGrouped = await TransactionDao.getExpensesGrouped();
    final incomeGrouped = await TransactionDao.getIncomeGrouped();
    final transferImpact = await TransactionDao.getTransferImpact(); // ✅ NEW

    double totalBalance = 0;
    double totalIncome = 0;
    double totalExpense = 0;

    final List<AccountModel> accounts = [];
    final Map<int, double> balances = {};

    for (var map in accountData) {
      final account = AccountModel.fromMap(map);
      final id = account.id!;

      final initial = (map['initial_amount'] as num?)?.toDouble() ?? 0.0;
      final income = incomeGrouped[id] ?? 0.0;
      final expense = expensesGrouped[id] ?? 0.0;
      final transfer = transferImpact[id] ?? 0.0; // ✅ NEW: Get transfer impact

      // ✅ NEW: Balance = initial + income - expense + transfer impact
      // Transfer impact is: (money received from transfers) - (money sent via transfers)
      final balance = initial + income - expense + transfer;

      balances[id] = balance;
      account.balance = balance;
      accounts.add(account);

      totalBalance += balance;
      totalIncome += income;
      totalExpense += expense;
    }

    setState(() {
      state = AccountsState(
        accounts: accounts,
        totalBalance: totalBalance,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balances: balances,
      );
      isLoading = false;
    });
  }

  void _openAddAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateAccountDialog(onAdded: loadAccounts),
    );
  }

  void _openEditAccountDialog(AccountModel account) {
    showDialog(
      context: context,
      builder: (_) =>
          EditAccountDialog(account: account, onAdded: loadAccounts),
    );
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text("Are you sure you want to delete ${account.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  void _showTransactions(AccountModel acc) {
    AccountTransactionsBottomSheet.show(
      context,
      acc,
      onTransactionUpdated: loadAccounts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Accounts",
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: SvgPicture.asset(
            ImagePaths.icMenu,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openAddAccountDialog,
            icon: SvgPicture.asset(
              ImagePaths.icAdd,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadAccounts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _summary(theme),
                    const SizedBox(height: 16),
                    state.accounts.isEmpty
                        ? _emptyState(theme)
                        : _accountList(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summary(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "[ All Accounts ${state.totalBalance >= 0 ? '' : '-'}${PrefCurrencySymbol.rupee}${state.totalBalance.abs().toStringAsFixed(2)} ]",
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
                child: _summaryItem(
                  "EXPENSE",
                  state.totalExpense,
                  Colors.red.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _summaryItem(
                  "INCOME",
                  state.totalIncome,
                  Colors.green.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 3),
        Text(
          "${PrefCurrencySymbol.rupee}${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _accountList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Accounts", style: theme.textTheme.titleLarge),
        ),
        ...state.accounts.asMap().entries.map(
          (e) => AccountCard(
            account: e.value,
            index: e.key + 1,
            onTap: () => _showTransactions(e.value),
            onEdit: () => _openEditAccountDialog(e.value),
            onDelete: () => _deleteAccount(e.value),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          SvgPicture.asset(
            ImagePaths.icWallet,
            color: Theme.of(context).colorScheme.primary,
            height: 64,
          ),

          const SizedBox(height: 16),
          Text("No accounts added", style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            "Tap + to add your first account",
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// ---------- INLINE ACCOUNT CARD WIDGET ----------

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AccountCard({
    super.key,
    required this.account,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = account.balance;
    final isNegative = balance < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
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
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Balance: ",
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                        Text(
                          "${isNegative ? '-' : ''}${PrefCurrencySymbol.rupee}${balance.abs().toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isNegative ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == "edit") onEdit();
                  if (value == "delete") onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
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
    );
  }
}

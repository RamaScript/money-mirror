import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:money_mirror/core/utils/ui_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/models/account_model.dart';
import 'package:money_mirror/views/widgets/account/create_account_dialog.dart';
import 'package:money_mirror/views/widgets/account/edit_account_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<AccountModel> accounts = [];

  Future<void> loadAccounts() async {
    final accountData = await AccountDao.getAccounts();
    setState(() {
      accounts = accountData.map((e) => AccountModel.fromMap(e)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadAccounts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accounts"),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(onPressed: _openAddAccountDialog, icon: Icon(Icons.add)),
        ],
      ),
      body: accounts.isEmpty
          ? Center(child: Text("No accounts added"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  UiUtils.buildListHeader(title: "Your Accounts"),
                  ListView.builder(
                    itemCount: accounts.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return ListTile(
                        leading: Text(
                          account.icon,
                          style: TextStyle(fontSize: 32),
                        ),
                        title: Text(account.name),
                        subtitle: Text(
                          "Initial: ${PrefCurrencySymbol.rupee + account.initialAmount.toStringAsFixed(2)}",
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: PopupMenuButton(
                          icon: Icon(Icons.more_horiz),
                          onSelected: (v) {
                            if (v == "edit") {
                              _openEditAccountDialog(account: account);
                            } else if (v == "delete") {
                              AccountDao.deleteAccount(account.id!);
                              loadAccounts();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "edit",
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text("Edit"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text("Delete"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

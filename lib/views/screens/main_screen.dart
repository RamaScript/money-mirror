import 'package:flutter/material.dart';
import 'package:money_mirror/views/screens/accounts_screen.dart';
import 'package:money_mirror/views/screens/add_transaction_screen.dart';
import 'package:money_mirror/views/screens/analysis_screen.dart';
import 'package:money_mirror/views/screens/budget_screen.dart';
import 'package:money_mirror/views/screens/categories_screen.dart';
import 'package:money_mirror/views/screens/home_screen.dart';
import 'package:money_mirror/views/widgets/main_drawer_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _homeRefreshId = 0;

  final List<Widget Function(int)> screens = [
    (id) => HomeScreen(key: ValueKey('home_$id')),
    (id) => AnalysisScreen(key: ValueKey('analysis_$id')),
    (id) => BudgetScreen(key: ValueKey('budget_$id')),
    (id) => AccountsScreen(key: ValueKey('accounts_$id')),
    (id) => CategoriesScreen(key: ValueKey('categories_$id')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MainDrawerWidget(),
      body: screens[_currentIndex](_homeRefreshId),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Analysis",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: "Budget"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Category",
          ),
        ],
      ),
    );
  }

  void _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionScreen()),
    );

    if (result == true) {
      // bump the id so HomeScreen gets a new key -> new State -> initState()
      setState(() => _homeRefreshId++);
    }
  }
}

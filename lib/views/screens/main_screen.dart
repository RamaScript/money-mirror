import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:money_mirror/core/utils/image_paths.dart';
import 'package:money_mirror/views/screens/accounts_screen.dart';
import 'package:money_mirror/views/screens/add_transaction_screen.dart';
import 'package:money_mirror/views/screens/analysis/analysis_screen.dart';
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
        child: SvgPicture.asset(
          ImagePaths.icAdd,
          color: Theme.of(context).colorScheme.secondary,
          height: 20,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,

        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w100),

        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: navIcon(ImagePaths.icHome, 0),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: navIcon(ImagePaths.icGraph, 1),
            label: "Analysis",
          ),
          BottomNavigationBarItem(
            icon: navIcon(ImagePaths.icBudget, 2),
            label: "Budget",
          ),
          BottomNavigationBarItem(
            icon: navIcon(ImagePaths.icWallet, 3),
            label: "Account",
          ),
          BottomNavigationBarItem(
            icon: navIcon(ImagePaths.icCategory, 4),
            label: "Category",
          ),
        ],
      ),
    );
  }

  Widget navIcon(String path, int index) {
    return SvgPicture.asset(
      path,
      width: 24,
      height: 24,
      color: _currentIndex == index
          ? Theme.of(context).colorScheme.primary
          : Colors.grey,
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

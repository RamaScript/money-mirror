import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/app_colors.dart';
import 'package:money_mirror/core/utils/pref_currency_symbol.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = PrefCurrencySymbol.rupee;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency =
        prefs.getString('currency_symbol') ?? PrefCurrencySymbol.rupee;
    setState(() {});
  }

  Future<void> _saveCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', value);
    setState(() => _selectedCurrency = value);
  }

  void _openCurrencySelector() {
    showModalBottomSheet(
      context: context,
      elevation: 8,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Select Currency",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 10),

              // Currency List
              ...[
                ("₹ Rupee", PrefCurrencySymbol.rupee),
                ("\$ Dollar", PrefCurrencySymbol.dollar),
                ("€ Euro", PrefCurrencySymbol.euro),
                ("£ Pound", PrefCurrencySymbol.pound),
                ("¥ Yen", PrefCurrencySymbol.yen),
                ("₣ Franc", PrefCurrencySymbol.franc),
                ("₩ Won", PrefCurrencySymbol.won),
                ("₽ Ruble", PrefCurrencySymbol.ruble),
                ("₺ Lira", PrefCurrencySymbol.lira),
                ("₱ Peso", PrefCurrencySymbol.peso),
              ].map((item) => _currencyOption(item.$1, item.$2)),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _currencyOption(String label, String value) {
    final selected = value == _selectedCurrency;
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        _saveCurrency(value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingsCard(
            icon: Icons.currency_exchange_rounded,
            title: "Currency Symbol",
            subtitle: _selectedCurrency,
            onTap: _openCurrencySelector,
          ),
        ],
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      color: AppColors.primaryColor.withAlpha(95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

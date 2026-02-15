import 'package:flutter/material.dart';
import 'package:gastos_inteligentes/screens/widgets/expandible_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'debts_list_screen.dart';
import 'movements_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    // Navigate to login if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_selectedIndex == 0 ? 'Control de Gastos' : 'Deudas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _selectedIndex == 0 ? const MovementsScreen() : const DebtsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Movimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Deudas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? ExpandableFab(
              icon: Icon(
                Icons.monetization_on_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddIncomeScreen(),
                      ),
                    );
                  },
                  heroTag: 'add_income',
                  backgroundColor: Colors.green[400],
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddExpenseScreen(),
                      ),
                    );
                  },
                  heroTag: 'add_expense',
                  backgroundColor: Colors.red[400],
                  child: const Icon(Icons.wallet, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }
}

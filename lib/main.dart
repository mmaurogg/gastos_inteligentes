import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'screens/api_key_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasApiKey = prefs.containsKey('gemini_api_key');
  runApp(MyApp(hasApiKey: hasApiKey));
}

class MyApp extends StatelessWidget {
  final bool hasApiKey;
  const MyApp({super.key, required this.hasApiKey});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ExpenseProvider())],
      child: MaterialApp(
        title: 'Control de Gastos IA',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: hasApiKey ? const HomeScreen() : const ApiKeyScreen(),
      ),
    );
  }
}

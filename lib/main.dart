import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_inteligentes/config/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos Inteligentes',
      theme: ThemeData(
        colorScheme: AppTheme().themeApp.colorScheme,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

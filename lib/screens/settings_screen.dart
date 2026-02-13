import 'package:flutter/material.dart';
import 'backup_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Respaldo y Restauración'),
            subtitle: const Text('Exporta o recupera tu información'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupPage()),
              );
            },
          ),
          const Divider(),
          // Posibilidad de añadir más ajustes aquí en el futuro
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleBackup(
    Future<void> Function() backupFn,
    String successMsg,
  ) async {
    setState(() => _isLoading = true);
    try {
      await backupFn();
      _showSnackBar(successMsg);
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore(
    Future<bool> Function() restoreFn,
    String successMsg,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text(
          'Esta acción modificará tus datos actuales. Se recomienda hacer un respaldo primero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await restoreFn();
      if (success) {
        _showSnackBar(successMsg);
        // Refresh providers to reflect changes
        ref.read(expenseProvider).loadExpenses();
        ref.read(incomeProvider).loadIncomes();
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCsvImport(
    Future<int> Function() importFn,
    String type,
  ) async {
    setState(() => _isLoading = true);
    try {
      final count = await importFn();
      if (count >= 0) {
        _showSnackBar('Se importaron $count registros de $type exitosamente.');
        // Refresh providers
        ref.read(expenseProvider).loadExpenses();
        ref.read(incomeProvider).loadIncomes();
      } else {
        // -1 means cancelled
        // _showSnackBar('Importación cancelada');
      }
    } catch (e) {
      _showSnackBar('Error importando CSV: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader('EXPORTAR'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.storage, color: Colors.blue),
                        title: const Text('Exportar como .db (SQL)'),
                        subtitle: const Text(
                          'Formato recomendado para restaurar exactamente igual.',
                        ),
                        onTap: () => _handleBackup(
                          _backupService.exportDatabase,
                          'Respaldo SQL generado',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.table_chart,
                          color: Colors.green,
                        ),
                        title: const Text('Exportar como CSV'),
                        subtitle: const Text(
                          'Para ver tus datos en Excel o Google Sheets.',
                        ),
                        onTap: () => _handleBackup(
                          _backupService.exportToCSV,
                          'Archivos CSV generados',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('PLANTILLAS'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download, color: Colors.blueGrey),
                    title: const Text('Descargar Plantillas de Ejemplo'),
                    subtitle: const Text(
                      'Obtén archivos CSV con la estructura correcta para importar datos.',
                    ),
                    onTap: () => _handleBackup(
                      _backupService.downloadTemplates,
                      'Plantillas generadas correctamente',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('IMPORTAR (CSV)'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.file_upload,
                          color: Colors.purple,
                        ),
                        title: const Text('Importar Gastos (.csv)'),
                        subtitle: const Text(
                          'Agrega gastos desde un archivo CSV a tu lista actual.',
                        ),
                        onTap: () => _handleCsvImport(
                          _backupService.importExpensesFromCSV,
                          'gastos',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.file_upload,
                          color: Colors.teal,
                        ),
                        title: const Text('Importar Ingresos (.csv)'),
                        subtitle: const Text(
                          'Agrega ingresos desde un archivo CSV a tu lista actual.',
                        ),
                        onTap: () => _handleCsvImport(
                          _backupService.importIncomesFromCSV,
                          'ingresos',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('RESTAURAR (BASE DE DATOS)'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.settings_backup_restore,
                          color: Colors.orange,
                        ),
                        title: const Text('Restaurar .db (Combinar)'),
                        subtitle: const Text(
                          'Añade datos de un backup .db a tus datos actuales.',
                        ),
                        onTap: () => _handleRestore(
                          _backupService.restoreDatabaseMerge,
                          'Datos combinados con éxito',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                        ),
                        title: const Text('Restaurar .db (Sobrescribir)'),
                        subtitle: const Text(
                          'REMPLAZA todo con el archivo de respaldo.',
                        ),
                        onTap: () => _handleRestore(
                          _backupService.restoreDatabaseOverwrite,
                          'Base de datos restaurada por completo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Nota: Los archivos .db solo pueden ser restaurados por esta aplicación. Los CSV son para visualización externa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
    );
  }
}

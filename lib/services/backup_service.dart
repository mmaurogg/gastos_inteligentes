import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // EXPORT AS .DB
  Future<void> exportDatabase() async {
    try {
      String dbPath = join(await getDatabasesPath(), 'expenses.db');
      File dbFile = File(dbPath);

      if (await dbFile.exists()) {
        final directory = await getTemporaryDirectory();
        final backupPath = join(
          directory.path,
          'gastos_backup_${DateTime.now().millisecondsSinceEpoch}.db',
        );

        // Copy the database file to a temporary location for sharing
        await dbFile.copy(backupPath);

        await Share.shareXFiles([
          XFile(backupPath),
        ], text: 'Respaldo de Gastos Inteligentes (SQL)');
      }
    } catch (e) {
      print('Error exporting database: $e');
    }
  }

  // EXPORT AS CSV
  Future<void> exportToCSV() async {
    try {
      final expenses = await _dbHelper.getTableData('expenses');
      final incomes = await _dbHelper.getTableData('incomes');

      List<List<dynamic>> expenseRows = [
        ['id', 'name', 'category', 'amount', 'date'],
      ];
      for (var row in expenses) {
        expenseRows.add([
          row['id'],
          row['name'],
          row['category'],
          row['amount'],
          row['date'],
        ]);
      }

      List<List<dynamic>> incomeRows = [
        ['id', 'name', 'category', 'amount', 'date'],
      ];
      for (var row in incomes) {
        incomeRows.add([
          row['id'],
          row['name'],
          row['category'],
          row['amount'],
          row['date'],
        ]);
      }

      String csvExpenses = const ListToCsvConverter().convert(expenseRows);
      String csvIncomes = const ListToCsvConverter().convert(incomeRows);

      final directory = await getTemporaryDirectory();
      final pathExpenses = join(
        directory.path,
        'expenses_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      final pathIncomes = join(
        directory.path,
        'incomes_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      File(pathExpenses).writeAsStringSync(csvExpenses);
      File(pathIncomes).writeAsStringSync(csvIncomes);

      await Share.shareXFiles([
        XFile(pathExpenses),
        XFile(pathIncomes),
      ], text: 'Respaldo de Gastos Inteligentes (CSV)');
    } catch (e) {
      print('Error exporting to CSV: $e');
    }
  }

  // RESTORE (OVERWRITE)
  Future<bool> restoreDatabaseOverwrite() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType
            .any, // .db files don't always have a strict type on mobile pickers
      );

      if (result != null && result.files.single.path != null) {
        File backupFile = File(result.files.single.path!);

        // Close current database
        await _dbHelper.closeDatabase();

        String dbPath = join(await getDatabasesPath(), 'expenses.db');

        // Replace the database file
        await backupFile.copy(dbPath);

        return true;
      }
      return false;
    } catch (e) {
      print('Error restoring database: $e');
      return false;
    }
  }

  // RESTORE (MERGE)
  Future<bool> restoreDatabaseMerge() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        String backupPath = result.files.single.path!;
        Database backupDb = await openDatabase(backupPath);

        // Get data from backup
        List<Map<String, dynamic>> expenses = await backupDb.query('expenses');
        List<Map<String, dynamic>> incomes = await backupDb.query('incomes');

        await backupDb.close();

        // Merge into current database
        for (var expense in expenses) {
          // Remove ID to let DB generate a new one if it conflicts,
          // or use insertMap with ConflictAlgorithm.replace
          Map<String, dynamic> data = Map.from(expense);
          data.remove('id');
          await _dbHelper.insertMap('expenses', data);
        }

        for (var income in incomes) {
          Map<String, dynamic> data = Map.from(income);
          data.remove('id');
          await _dbHelper.insertMap('incomes', data);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error merging database: $e');
      return false;
    }
  }

  // IMPORT CSV (EXPENSES)
  Future<int> importExpensesFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        File csvFile = File(result.files.single.path!);
        String csvString = await csvFile.readAsString();
        List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvString,
        );

        if (rows.isEmpty) return 0;

        // Assumes header row exists, skip it
        // Expected columns: id, name, category, amount, date
        // We verify header or just assume structure based on our export
        int importedCount = 0;

        // Simple validation: check if first row looks like header
        int startIndex = 0;
        if (rows.isNotEmpty && rows[0].any((e) => e.toString() == 'amount')) {
          startIndex = 1;
        }

        for (int i = startIndex; i < rows.length; i++) {
          var row = rows[i];
          if (row.length < 5) continue; // Skip invalid rows

          // Map CSV row to database map
          // Export order: id, name, category, amount, date
          // Import: Ignore ID, take others
          Map<String, dynamic> data = {
            'name': row[1].toString(),
            'category': row[2].toString(),
            'amount': row[3] is num
                ? row[3]
                : double.tryParse(row[3].toString()) ?? 0.0,
            'date': row[4].toString(),
          };

          await _dbHelper.insertMap('expenses', data);
          importedCount++;
        }
        return importedCount;
      }
      return -1; // Cancelled
    } catch (e) {
      print('Error importing expenses CSV: $e');
      throw e;
    }
  }

  // IMPORT CSV (INCOMES)
  Future<int> importIncomesFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        File csvFile = File(result.files.single.path!);
        String csvString = await csvFile.readAsString();
        List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvString,
        );

        if (rows.isEmpty) return 0;

        int importedCount = 0;
        int startIndex = 0;
        if (rows.isNotEmpty && rows[0].any((e) => e.toString() == 'amount')) {
          startIndex = 1;
        }

        for (int i = startIndex; i < rows.length; i++) {
          var row = rows[i];
          if (row.length < 5) continue;

          Map<String, dynamic> data = {
            'name': row[1].toString(),
            'category': row[2].toString(),
            'amount': row[3] is num
                ? row[3]
                : double.tryParse(row[3].toString()) ?? 0.0,
            'date': row[4].toString(),
          };

          await _dbHelper.insertMap('incomes', data);
          importedCount++;
        }
        return importedCount;
      }
      return -1; // Cancelled
    } catch (e) {
      print('Error importing incomes CSV: $e');
      throw e;
    }
  }

  // DOWNLOAD TEMPLATES
  Future<void> downloadTemplates() async {
    try {
      // 1. Define headers and example rows
      List<List<dynamic>> expenseTemplate = [
        ['id', 'name', 'category', 'amount', 'date'],
        [0, 'Ejemplo Gasto', 'Comida', 50.00, DateTime.now().toString()],
      ];

      List<List<dynamic>> incomeTemplate = [
        ['id', 'name', 'category', 'amount', 'date'],
        [0, 'Ejemplo Ingreso', 'Salario', 1500.00, DateTime.now().toString()],
      ];

      // 2. Convert to CSV
      String csvExpense = const ListToCsvConverter().convert(expenseTemplate);
      String csvIncome = const ListToCsvConverter().convert(incomeTemplate);

      // 3. Save to temp files
      final directory = await getTemporaryDirectory();
      final pathExpense = join(directory.path, 'plantilla_gastos.csv');
      final pathIncome = join(directory.path, 'plantilla_ingresos.csv');

      File(pathExpense).writeAsStringSync(csvExpense);
      File(pathIncome).writeAsStringSync(csvIncome);

      // 4. Share files
      await Share.shareXFiles([
        XFile(pathExpense),
        XFile(pathIncome),
      ], text: 'Plantillas CSV para Importación');
    } catch (e) {
      print('Error downloading templates: $e');
      throw e;
    }
  }
}

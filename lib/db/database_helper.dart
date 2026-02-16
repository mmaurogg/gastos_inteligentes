import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt/debt.dart';
import '../models/debt/debt_purchase.dart';
import '../models/debt/debt_payment.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expenses.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          category TEXT,
          amount REAL,
          date TEXT
        )
        ''');
      await db.execute('''
        CREATE TABLE incomes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          category TEXT,
          amount REAL,
          date TEXT
        )
        ''');

      await db.execute('''
        CREATE TABLE debts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          expenseId INTEGER,
          originalAmount REAL,
          paidAmount REAL,
          interestRate REAL,
          interestAmount REAL,
          createdAt TEXT,
          dueDate TEXT,
          paidAt TEXT,
          status TEXT,
          FOREIGN KEY (expenseId) REFERENCES expenses (id) ON DELETE CASCADE
        )
        ''');
    }

    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE expenses ADD COLUMN debtPurchaseId INTEGER',
        );
      } catch (e) {
        print("Column debtPurchaseId might already exist: $e");
      }
    }

    if (oldVersion < 6) {
      // 1. Rename old 'debts' table to 'debt_purchases'
      try {
        await db.execute('ALTER TABLE debts RENAME TO debt_purchases');
      } catch (e) {
        print("Error renaming debts table: $e");
      }

      // 2. Create new 'debts' table for Debt Accounts
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          debtPurchase INTEGER,
          paymentDay INTEGER,
          interestRate REAL
        )
      ''');

      // 3. Create 'debt_payments' table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debt_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          debtId INTEGER,
          amount REAL,
          date TEXT,
          paymentMethod TEXT,
          purchaseId INTEGER,
          FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE,
           FOREIGN KEY (purchaseId) REFERENCES debt_purchases (id) ON DELETE CASCADE
        )
      ''');

      try {
        await db.execute(
          'ALTER TABLE debt_purchases ADD COLUMN debtId INTEGER',
        );
      } catch (e) {
        print("Error adding debtId to debt_purchases: $e");
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        amount REAL,
        date TEXT,
        debtPurchaseId INTEGER,
        FOREIGN KEY (debtPurchaseId) REFERENCES debt_purchases (id) ON DELETE CASCADE
      )
      ''');
    await db.execute('''
      CREATE TABLE incomes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        amount REAL,
        date TEXT
      )
      ''');

    // New Tables
    await db.execute('''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        debtPurchase INTEGER,
        paymentDay INTEGER,
        interestRate REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE debt_purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expenseId INTEGER,
        debtId INTEGER,
        originalAmount REAL,
        paidAmount REAL,
        interestAmount REAL,
        createdAt TEXT,
        dueDate TEXT,
        paidAt TEXT,
        status TEXT,
        FOREIGN KEY (expenseId) REFERENCES expenses (id) ON DELETE CASCADE,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE debt_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER,
        amount REAL,
        date TEXT,
        paymentMethod TEXT,
        purchaseId INTEGER,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE,
        FOREIGN KEY (purchaseId) REFERENCES debt_purchases (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertExpense(Expense expense) async {
    Database db = await database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateExpense(Expense expense) async {
    Database db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<List<Expense>> getExpenses() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: "date DESC",
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<Expense?> getExpenseById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteExpense(int id) async {
    Database db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpenses() async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses',
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  // Income Methods
  Future<int> insertIncome(Income income) async {
    Database db = await database;
    return await db.insert(
      'incomes',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateIncome(Income income) async {
    Database db = await database;
    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<List<Income>> getIncomes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'incomes',
      orderBy: "date DESC",
    );

    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<void> deleteIncome(int id) async {
    Database db = await database;
    await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalIncomes() async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM incomes',
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  // Debt Methods (Updated)
  Future<int> insertDebt(Debt debt) async {
    Database db = await database;
    return await db.insert(
      'debts',
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDebt(Debt debt) async {
    Database db = await database;
    return await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<List<Debt>> getDebts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      orderBy: "name ASC",
    );

    return List.generate(maps.length, (i) {
      return Debt.fromMap(maps[i]);
    });
  }

  Future<Debt?> getDebtById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Debt.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteDebt(int id) async {
    Database db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // Debt Purchase Methods
  Future<int> insertDebtPurchase(DebtPurchase purchase) async {
    Database db = await database;
    return await db.insert(
      'debt_purchases',
      purchase.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDebtPurchase(DebtPurchase purchase) async {
    Database db = await database;
    return await db.update(
      'debt_purchases',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<List<DebtPurchase>> getDebtPurchases() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debt_purchases',
      orderBy: "createdAt DESC",
    );

    return List.generate(maps.length, (i) {
      return DebtPurchase.fromMap(maps[i]);
    });
  }

  Future<DebtPurchase?> getDebtPurchaseById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debt_purchases',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return DebtPurchase.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteDebtPurchase(int id) async {
    Database db = await database;
    await db.delete('debt_purchases', where: 'id = ?', whereArgs: [id]);
  }

  // Debt Payment Methods
  Future<int> insertDebtPayment(DebtPayment payment) async {
    Database db = await database;
    return await db.insert(
      'debt_payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDebtPayment(DebtPayment payment) async {
    Database db = await database;
    return await db.update(
      'debt_payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<List<DebtPayment>> getDebtPayments() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debt_payments',
      orderBy: "date DESC",
    );

    return List.generate(maps.length, (i) {
      return DebtPayment.fromMap(maps[i]);
    });
  }

  Future<void> deleteDebtPayment(int id) async {
    Database db = await database;
    await db.delete('debt_payments', where: 'id = ?', whereArgs: [id]);
  }
}

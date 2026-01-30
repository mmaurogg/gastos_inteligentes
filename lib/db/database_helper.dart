import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';

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
      version: 5,
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
      await db.execute('ALTER TABLE expenses ADD COLUMN debtId INTEGER');
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
        debtId INTEGER
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

  // Debt Methods
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
      orderBy: "dueDate DESC",
    );

    return List.generate(maps.length, (i) {
      return Debt.fromMap(maps[i]);
    });
  }

  Future<void> deleteDebt(int id) async {
    Database db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }
}

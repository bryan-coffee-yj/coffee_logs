import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/coffee_bean.dart';
import '../models/brew_log.dart';
import '../models/brew_method.dart'; // Import our new model!

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('coffee_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // Fresh start with a clean tables schema!
      onCreate: _createDB,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const intNullableType = 'INTEGER';
    const realType = 'REAL NOT NULL';
    const realTypeNullable = 'REAL';

    // 1. Create Beans Table
    await db.execute('''
    CREATE TABLE coffee_beans (
      id $idType,
      roasterName $textType,
      beanName $textType,
      roastLevel $textType,
      roastDate $textType,
      price $realTypeNullable,
      initialWeight $realType,
      currentWeight $realType
    )
    ''');

    // 2. NEW: Create Brew Methods Table
    await db.execute('''
    CREATE TABLE brew_methods (
      id $idType,
      methodName $textType,
      brewMethodType $textType,
      defaultDose $realType,
      defaultWater $realType,
      stepsJson $textType
    )
    ''');

    // 3. Create Brew Logs Table 
    await db.execute('''
    CREATE TABLE brew_logs (
      id $idType,
      beanId $intType,
      methodId $intNullableType, 
      dateOfMaking $textType,
      brewMethod $textType,
      appliedMethod $textType, -- <--- NEW: Added this line!
      equipment $textType,
      grinder $textType,
      grindSize $textType,
      dose $realType,
      waterMass $realType,
      temperature $realType,
      brewTimeSeconds $intType,
      acidityScore $intType,
      sweetnessScore $intType,
      bodyScore $intType,
      tastingNotes $textType,
      FOREIGN KEY (beanId) REFERENCES coffee_beans (id) ON DELETE CASCADE,
      FOREIGN KEY (methodId) REFERENCES brew_methods (id) ON DELETE SET NULL
    )
    ''');
  }

  // --- COFFEE BEAN CRUD ---
  Future<int> insertCoffeeBean(CoffeeBean bean) async {
    final db = await instance.database;
    return await db.insert('coffee_beans', bean.toMap());
  }

  Future<List<CoffeeBean>> getAllCoffeeBeans() async {
    final db = await instance.database;
    final result = await db.query('coffee_beans', orderBy: 'id DESC');
    return result.map((json) => CoffeeBean.fromMap(json)).toList();
  }

  Future<int> updateCoffeeBean(CoffeeBean bean) async {
    final db = await instance.database;
    return await db.update(
      'coffee_beans',
      bean.toMap(),
      where: 'id = ?',
      whereArgs: [bean.id],
    );
  }

  Future<int> deleteCoffeeBean(int id) async {
    final db = await instance.database;
    return await db.delete('coffee_beans', where: 'id = ?', whereArgs: [id]);
  }

  // --- NEW: BREW METHOD CRUD ---
  Future<int> insertBrewMethod(BrewMethod method) async {
    final db = await instance.database;
    return await db.insert('brew_methods', method.toMap());
  }

  Future<List<BrewMethod>> getAllBrewMethods() async {
    final db = await instance.database;
    final result = await db.query('brew_methods', orderBy: 'id DESC');
    return result.map((json) => BrewMethod.fromMap(json)).toList();
  }

  Future<int> updateBrewMethod(BrewMethod method) async {
    final db = await instance.database;
    return await db.update(
      'brew_methods',
      method.toMap(),
      where: 'id = ?',
      whereArgs: [method.id],
    );
  }

  Future<int> deleteBrewMethod(int id) async {
    final db = await instance.database;
    return await db.delete('brew_methods', where: 'id = ?', whereArgs: [id]);
  }

  // --- BREW LOG CRUD ---
  Future<int> insertBrewLog(BrewLog log) async {
    final db = await instance.database;
    return await db.insert('brew_logs', log.toMap());
  }

  Future<List<BrewLog>> getBrewLogsForBean(int beanId) async {
    final db = await instance.database;
    final result = await db.query(
      'brew_logs',
      where: 'beanId = ?',
      whereArgs: [beanId],
      orderBy: 'dateOfMaking DESC',
    );
    return result.map((json) => BrewLog.fromMap(json)).toList();
  }

  Future<BrewLog?> getLatestBrewLogForBean(int beanId) async {
    final db = await instance.database;
    final result = await db.query(
      'brew_logs',
      where: 'beanId = ?',
      whereArgs: [beanId],
      orderBy: 'dateOfMaking DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return BrewLog.fromMap(result.first);
    return null;
  }

  Future<List<BrewLog>> getAllBrewLogs() async {
    final db = await instance.database;
    final result = await db.query('brew_logs', orderBy: 'dateOfMaking DESC');
    return result.map((json) => BrewLog.fromMap(json)).toList();
  }

  Future<int> deleteBrewLog(int id) async {
    final db = await instance.database;
    return await db.delete('brew_logs', where: 'id = ?', whereArgs: [id]);
  }
}

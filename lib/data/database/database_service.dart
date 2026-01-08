import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  static Database? _database;
  final Logger _logger = Logger();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'timeflow.db');

    _logger.i("正在打开数据库: $path");

    return await openDatabase(
      path,
      version: 4, // 升级到版本 4
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  // 数据库升级逻辑 - 更健壮的版本
  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    _logger.i("数据库升级: 从版本 $oldVersion 到 $newVersion");

    if (oldVersion < 2) {
      // 检查列是否已存在
      final result = await db.rawQuery('PRAGMA table_info(tasks)');
      final columns = result.map((col) => col['name'] as String).toList();

      if (!columns.contains('due_date_ms')) {
        await db.execute('ALTER TABLE tasks ADD COLUMN due_date_ms INTEGER');
        _logger.i("✅ 添加 due_date_ms 字段");
      }
    }

    if (oldVersion < 3) {
      // 再次确保字段存在
      final result = await db.rawQuery('PRAGMA table_info(tasks)');
      final columns = result.map((col) => col['name'] as String).toList();

      if (!columns.contains('due_date_ms')) {
        await db.execute('ALTER TABLE tasks ADD COLUMN due_date_ms INTEGER');
        _logger.i("✅ [v3] 添加 due_date_ms 字段");
      }
    }

    if (oldVersion < 4) {
      _logger.i("升级到 v4: 添加 user_id 字段");

      // 1. Tasks 表添加 user_id
      var res = await db.rawQuery('PRAGMA table_info(tasks)');
      var cols = res.map((c) => c['name'] as String).toList();
      if (!cols.contains('user_id')) {
        await db.execute(
          "ALTER TABLE tasks ADD COLUMN user_id TEXT DEFAULT 'guest'",
        );
      }

      // 2. Records 表添加 user_id
      res = await db.rawQuery('PRAGMA table_info(records)');
      cols = res.map((c) => c['name'] as String).toList();
      if (!cols.contains('user_id')) {
        await db.execute(
          "ALTER TABLE records ADD COLUMN user_id TEXT DEFAULT 'guest'",
        );
      }
    }
  }

  // 创建表结构
  Future<void> _createDb(Database db, int version) async {
    _logger.i("创建新数据库，版本: $version");

    // 创建任务表
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        due_date_ms INTEGER,
        user_id TEXT DEFAULT 'guest'
      )
    ''');

    // 创建账单表
    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date_ms INTEGER NOT NULL,
        is_expense INTEGER NOT NULL,
        user_id TEXT DEFAULT 'guest'
      )
    ''');

    _logger.i("✅ 数据库表创建成功！");
  }
}

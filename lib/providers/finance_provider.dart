import 'package:flutter/foundation.dart'; // 引入 kIsWeb
import 'package:flutter/material.dart';
import '../data/database/database_service.dart';
import '../data/models/finance_record.dart';

class FinanceProvider with ChangeNotifier {
  List<FinanceRecord> _records = [];
  // Web 端使用的临时内存列表 (因为 Web 端 sqflite 需要复杂配置，且数据不持久化)
  final List<FinanceRecord> _webRecords = [];

  List<FinanceRecord> get records => _records;
  String _userId = 'guest';

  void updateUserId(String userId) {
    _userId = userId;
    loadRecords();
  }

  // --- 新增: 预算管理 ---
  double _monthlyBudget = 0.0; // 默认为0，表示未设置
  double get monthlyBudget => _monthlyBudget;

  void setBudget(double amount) {
    _monthlyBudget = amount;
    notifyListeners();
  }

  // 获取本月总支出
  double get totalExpense {
    return _records
        .where((r) => r.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // 获取本月总收入
  double get totalIncome {
    return _records
        .where((r) => !r.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // 1. 加载所有账单 (按日期倒序)
  Future<void> loadRecords() async {
    if (kIsWeb) {
      // Web 环境：直接使用内存数据
      _records = _webRecords.where((r) => r.userId == _userId).toList();
      // 内存排序
      _records.sort((a, b) => b.dateMs.compareTo(a.dateMs));
      notifyListeners();
      return;
    }

    // 移动/桌面端：使用 SQLite
    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      orderBy: 'date_ms DESC',
      where: 'user_id = ?',
      whereArgs: [_userId],
    );
    _records = maps.map((e) => FinanceRecord.fromMap(e)).toList();
    notifyListeners();
  }

  // 2. 添加账单
  Future<void> addRecord(FinanceRecord record) async {
    // Inject userId
    final recordWithUser = FinanceRecord(
      id: record.id,
      amount: record.amount,
      category: record.category,
      note: record.note,
      dateMs: record.dateMs,
      isExpense: record.isExpense,
      userId: _userId,
    );

    if (kIsWeb) {
      _webRecords.add(recordWithUser);
      await loadRecords();
      return;
    }

    final db = await DatabaseService.instance.database;
    await db.insert('records', recordWithUser.toMap());
    await loadRecords(); // 刷新列表
  }

  // 3. 删除账单
  Future<void> deleteRecord(int id) async {
    if (kIsWeb) {
      _webRecords.removeWhere((r) => r.id == id); // 注意：Web端如果不分配ID，这里可能删不掉
      await loadRecords();
      return;
    }

    final db = await DatabaseService.instance.database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
    await loadRecords();
  }

  // 4. 清空当前用户的所有账单
  Future<void> clearAllRecords() async {
    if (kIsWeb) {
      _webRecords.removeWhere((r) => r.userId == _userId);
      await loadRecords();
      return;
    }
    final db = await DatabaseService.instance.database;
    await db.delete('records', where: 'user_id = ?', whereArgs: [_userId]);
    await loadRecords();
  }
}

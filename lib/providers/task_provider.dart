import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/database/database_service.dart';
import '../data/models/task.dart';

class TaskProvider with ChangeNotifier {
  // 1. 持有数据源
  // UI 只负责展示这个列表，不负责存
  List<Task> _tasks = [];
  // Web 端的内存数据
  final List<Task> _webTasks = [];

  // 2. 提供给 UI 的“只读”访问器
  // 为什么不直接把 _tasks 公开？为了安全，防止 UI 层不小心直接 _tasks.add() 却没通知刷新
  List<Task> get tasks => _tasks;

  String _userId = 'guest';

  void updateUserId(String userId) {
    _userId = userId;
    loadTasks();
  }

  // 3. 加载任务 (从数据库读取)
  Future<void> loadTasks() async {
    if (kIsWeb) {
      _tasks = _webTasks.where((t) => t.userId == _userId).toList();
      _tasks.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      notifyListeners();
      return;
    }

    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'id DESC',
      where: 'user_id = ?',
      whereArgs: [_userId],
    );

    _tasks = maps.map((e) => Task.fromMap(e)).toList();
    notifyListeners();
  }

  // 4. 添加任务
  Future<void> addTask(String title, {DateTime? dueDate}) async {
    print(
      '🔵 TaskProvider.addTask called with title: "$title", dueDate: $dueDate',
    );

    if (title.isEmpty) {
      print('❌ Title is empty, returning');
      return;
    }

    final newTask = Task(
      title: title,
      dueDateMs: dueDate?.millisecondsSinceEpoch,
      userId: _userId,
    );

    print('🔵 Created task object: ${newTask.toMap()}');

    if (kIsWeb) {
      final id =
          (_webTasks.isEmpty
              ? 0
              : (_webTasks
                    .map((e) => e.id ?? 0)
                    .reduce((a, b) => a > b ? a : b))) +
          1;
      _webTasks.add(newTask.copyWith(id: id));
      await loadTasks();
      print('✅ Task added to web storage');
      return;
    }

    try {
      final db = await DatabaseService.instance.database;
      print('🔵 Got database instance');

      final taskMap = newTask.toMap();
      print('🔵 Task map to insert: $taskMap');

      final id = await db.insert('tasks', taskMap);
      print('✅ Task inserted with ID: $id');

      await loadTasks();
      print('✅ Tasks reloaded, count: ${_tasks.length}');
    } catch (e, stackTrace) {
      print('❌ Error adding task: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // 5. 切换完成状态 (打钩/取消打钩)
  Future<void> toggleTask(Task task) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _webTasks[index] = task.copyWith(isDone: !task.isDone);
        await loadTasks();
      }
      return;
    }

    final db = await DatabaseService.instance.database;

    // 生成一个新的对象，状态取反
    final updatedTask = task.copyWith(isDone: !task.isDone);

    // 更新数据库：UPDATE tasks SET ... WHERE id = ?
    await db.update(
      'tasks',
      updatedTask.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    await loadTasks();
  }

  // 6. 删除任务
  Future<void> deleteTask(int id) async {
    if (kIsWeb) {
      _webTasks.removeWhere((t) => t.id == id);
      await loadTasks();
      return;
    }

    final db = await DatabaseService.instance.database;
    // DELETE FROM tasks WHERE id = ?
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);

    await loadTasks();
  }

  // 7. 清空当前用户的所有任务 (用于数据管理)
  Future<void> clearAllTasks() async {
    if (kIsWeb) {
      _webTasks.removeWhere((t) => t.userId == _userId);
      await loadTasks();
      return;
    }
    final db = await DatabaseService.instance.database;
    await db.delete('tasks', where: 'user_id = ?', whereArgs: [_userId]);
    await loadTasks();
  }
}

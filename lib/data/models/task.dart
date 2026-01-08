class Task {
  final int? id; // 数据库生成的 ID，新建时是空的
  final String title;
  final bool isDone;
  final int? dueDateMs; // 截止日期 (毫秒)
  final String userId; // 用户归属 (guest / user_xxx)

  Task({
    this.id,
    required this.title,
    this.isDone = false, // 默认未完成
    this.dueDateMs,
    this.userId = 'guest',
  });

  // --- 翻译官 1号：把 Map 转成 Object (从数据库读出来用) ---
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isDone: (map['is_done'] as int) == 1,
      dueDateMs: map['due_date_ms'],
      userId: map['user_id'] ?? 'guest',
    );
  }

  // --- 翻译官 2号：把 Object 转成 Map (存进数据库用) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_done': isDone ? 1 : 0,
      'due_date_ms': dueDateMs,
      'user_id': userId,
    };
  }

  // 辅助方法：复制一个新对象
  Task copyWith({
    int? id,
    String? title,
    bool? isDone,
    int? dueDateMs,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDateMs: dueDateMs ?? this.dueDateMs,
      userId: userId ?? this.userId,
    );
  }
}

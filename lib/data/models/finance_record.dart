class FinanceRecord {
  final int? id; // 数据库 ID
  final double amount; // 金额
  final String category; // 分类 (如：餐饮、交通)
  final String note; // 备注
  final int dateMs; // 日期 (存毫秒时间戳，方便排序)
  final bool isExpense; // true=支出, false=收入
  final String userId; // 用户归属

  FinanceRecord({
    this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.dateMs,
    this.isExpense = true,
    this.userId = 'guest',
  });

  // 1. 转为 Map 存入数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date_ms': dateMs,
      'is_expense': isExpense ? 1 : 0, // SQLite 不存 bool，转为 0/1
      'user_id': userId,
    };
  }

  // 2. 从数据库取出转为对象
  factory FinanceRecord.fromMap(Map<String, dynamic> map) {
    return FinanceRecord(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      note: map['note'],
      dateMs: map['date_ms'],
      isExpense: (map['is_expense'] as int) == 1,
      userId: map['user_id'] ?? 'guest',
    );
  }
}

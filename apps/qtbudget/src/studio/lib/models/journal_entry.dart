/// 日记账中的一笔流水。
///
/// income / expense 不同时 > 0，模型不做限制。balance 由 Journal 层汇总计算。
class JournalEntry {
  final String id;
  final String journalId;
  String description;
  double income;
  double expense;
  DateTime date;

  JournalEntry({
    required this.id,
    required this.journalId,
    required this.description,
    this.income = 0,
    this.expense = 0,
    required this.date,
  }) : assert(income >= 0 && expense >= 0);

  double get amount => income - expense;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journalId': journalId,
    'description': description,
    'income': income,
    'expense': expense,
    'date': date.toIso8601String(),
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    journalId: json['journalId'] as String,
    description: json['description'] as String? ?? '',
    income: (json['income'] as num?)?.toDouble() ?? 0,
    expense: (json['expense'] as num?)?.toDouble() ?? 0,
    date: DateTime.parse(json['date'] as String),
  );
}

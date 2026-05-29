class Entry {
  final String id;
  final String budgetId;
  String description;
  double amount;
  DateTime date;
  String? tagId;

  Entry({
    required this.id,
    required this.budgetId,
    required this.description,
    required this.amount,
    required this.date,
    this.tagId,
  });

  bool get isIncome => amount < 0;
  bool get isExpense => amount > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'budgetId': budgetId,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    if (tagId != null) 'tagId': tagId,
  };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
    id: json['id'] as String,
    budgetId: json['budgetId'] as String,
    description: json['description'] as String? ?? '',
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    tagId: json['tagId'] as String?,
  );
}

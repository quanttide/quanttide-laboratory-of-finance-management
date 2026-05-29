class Transaction {
  final String id;
  final String budgetId;
  String description;
  double amount;
  DateTime date;
  TransactionType type;
  String? tagId;

  Transaction({
    required this.id,
    required this.budgetId,
    required this.description,
    required this.amount,
    required this.date,
    this.type = TransactionType.expense,
    this.tagId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'budgetId': budgetId,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type.name,
    if (tagId != null) 'tagId': tagId,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    budgetId: json['budgetId'] as String,
    description: json['description'] as String? ?? '',
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    type: TransactionType.values.byName(json['type'] as String? ?? 'expense'),
    tagId: json['tagId'] as String?,
  );
}

enum TransactionType { income, expense }

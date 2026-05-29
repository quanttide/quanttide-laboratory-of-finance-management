import 'account_code.dart';

/// 收支记录
class Transaction {
  final String id;
  final String budgetId;
  final String accountCodeId;
  String description;
  double amount;
  DateTime date;
  TransactionType type;

  Transaction({
    required this.id,
    required this.budgetId,
    required this.accountCodeId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'budgetId': budgetId,
    'accountCodeId': accountCodeId,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type.name,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    budgetId: json['budgetId'] as String,
    accountCodeId: json['accountCodeId'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    type: TransactionType.values.byName(json['type'] as String? ?? 'expense'),
  );
}

enum TransactionType { income, expense }

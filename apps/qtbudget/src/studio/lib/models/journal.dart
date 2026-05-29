/// 现金日记账。
///
/// 一本账，记录一类资金的流入流出。balance 由流水汇总计算，不持久化。
class Journal {
  final String id;
  String name;
  double? startingBalance;
  DateTime createdAt;

  Journal({
    required this.id,
    required this.name,
    this.startingBalance,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startingBalance': startingBalance,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Journal.fromJson(Map<String, dynamic> json) => Journal(
    id: json['id'] as String,
    name: json['name'] as String,
    startingBalance: (json['startingBalance'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

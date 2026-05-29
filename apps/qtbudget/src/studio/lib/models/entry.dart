/// 日记账中的一笔流水。
///
/// inflow / outflow 不会同时 > 0，但模型不做限制。balance 由 Journal 层汇总计算。
class Entry {
  final String id;
  final String journalId;
  String description;
  double inflow;
  double outflow;
  DateTime date;

  Entry({
    required this.id,
    required this.journalId,
    required this.description,
    this.inflow = 0,
    this.outflow = 0,
    required this.date,
  }) : assert(inflow >= 0 && outflow >= 0);

  double get amount => inflow - outflow;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journalId': journalId,
    'description': description,
    'inflow': inflow,
    'outflow': outflow,
    'date': date.toIso8601String(),
  };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
    id: json['id'] as String,
    journalId: json['journalId'] as String,
    description: json['description'] as String? ?? '',
    inflow: (json['inflow'] as num?)?.toDouble() ?? 0,
    outflow: (json['outflow'] as num?)?.toDouble() ?? 0,
    date: DateTime.parse(json['date'] as String),
  );
}

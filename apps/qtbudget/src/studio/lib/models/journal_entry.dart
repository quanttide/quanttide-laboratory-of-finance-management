enum LineType { debit, credit }

/// 分录行 — 借或贷，一个方向一个金额
class JournalEntryLine {
  final String id;
  LineType type;
  double amount;
  String description;
  DateTime createdAt;

  JournalEntryLine({
    required this.id,
    required this.type,
    this.amount = 0,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       assert(amount >= 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory JournalEntryLine.fromJson(Map<String, dynamic> json) =>
      JournalEntryLine(
        id: json['id'] as String,
        type: LineType.values.byName(json['type'] as String? ?? 'debit'),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 凭证 — 表头 + 分录行
class JournalEntry {
  final String id;
  final String journalId;
  DateTime createdAt;
  String description;
  List<JournalEntryLine> lines;

  JournalEntry({
    required this.id,
    required this.journalId,
    this.description = '',
    DateTime? createdAt,
    List<JournalEntryLine>? lines,
  }) : createdAt = createdAt ?? DateTime.now(),
       lines = lines ?? [];

  double get totalDebit =>
      lines.where((l) => l.type == LineType.debit).fold(0, (s, l) => s + l.amount);
  double get totalCredit =>
      lines.where((l) => l.type == LineType.credit).fold(0, (s, l) => s + l.amount);
  bool get isBalanced => totalDebit > 0 && totalDebit == totalCredit;
  double get amount => totalDebit - totalCredit;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journalId': journalId,
    'createdAt': createdAt.toIso8601String(),
    'description': description,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    journalId: json['journalId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    description: json['description'] as String? ?? '',
    lines: (json['lines'] as List?)
            ?.map((l) => JournalEntryLine.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

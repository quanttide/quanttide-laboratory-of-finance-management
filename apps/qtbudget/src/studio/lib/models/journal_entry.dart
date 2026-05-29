enum EntryStatus { draft, posted }

/// 分录行 — 一条借贷记录
class JournalEntryLine {
  final String id;
  double debit;
  double credit;
  String description;

  JournalEntryLine({
    required this.id,
    this.debit = 0,
    this.credit = 0,
    this.description = '',
  }) : assert(debit >= 0 && credit >= 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'debit': debit,
    'credit': credit,
    'description': description,
  };

  factory JournalEntryLine.fromJson(Map<String, dynamic> json) =>
      JournalEntryLine(
        id: json['id'] as String,
        debit: (json['debit'] as num?)?.toDouble() ?? 0,
        credit: (json['credit'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '',
      );
}

/// 凭证 — 表头 + 多行分录
class JournalEntry {
  final String id;
  final String journalId;
  DateTime entryDate;
  String description;
  EntryStatus status;
  List<JournalEntryLine> lines;

  JournalEntry({
    required this.id,
    required this.journalId,
    required this.entryDate,
    this.description = '',
    this.status = EntryStatus.draft,
    List<JournalEntryLine>? lines,
  }) : lines = lines ?? [];

  double get totalDebit => lines.fold(0, (s, l) => s + l.debit);
  double get totalCredit => lines.fold(0, (s, l) => s + l.credit);
  bool get isBalanced => totalDebit > 0 && totalDebit == totalCredit;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journalId': journalId,
    'entryDate': entryDate.toIso8601String(),
    'description': description,
    'status': status.name,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    journalId: json['journalId'] as String,
    entryDate: DateTime.parse(json['entryDate'] as String),
    description: json['description'] as String? ?? '',
    status: EntryStatus.values.byName(json['status'] as String? ?? 'draft'),
    lines: (json['lines'] as List?)
            ?.map((l) => JournalEntryLine.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

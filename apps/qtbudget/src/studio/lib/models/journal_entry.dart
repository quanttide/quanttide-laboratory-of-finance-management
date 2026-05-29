/// 一笔日记账分录。
class JournalEntry {
  final String id;
  final String journalId;
  DateTime entryDate;
  String description;
  double debit;
  double credit;

  JournalEntry({
    required this.id,
    required this.journalId,
    required this.entryDate,
    this.description = '',
    this.debit = 0,
    this.credit = 0,
  }) : assert(debit >= 0 && credit >= 0);

  double get amount => debit - credit;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journalId': journalId,
    'entryDate': entryDate.toIso8601String(),
    'description': description,
    'debit': debit,
    'credit': credit,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    journalId: json['journalId'] as String,
    entryDate: DateTime.parse(json['entryDate'] as String),
    description: json['description'] as String? ?? '',
    debit: (json['debit'] as num?)?.toDouble() ?? 0,
    credit: (json['credit'] as num?)?.toDouble() ?? 0,
  );
}

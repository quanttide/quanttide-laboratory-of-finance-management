class Budget {
  final String id;
  String name;
  double cap;
  String? note;
  DateTime createdAt;
  DateTime updatedAt;

  Budget({
    required this.id,
    required this.name,
    required this.cap,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cap': cap,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'] as String,
    name: json['name'] as String,
    cap: (json['cap'] as num).toDouble(),
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

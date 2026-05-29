import 'account_code.dart';

/// 预算
class Budget {
  final String id;
  String name;
  int year;
  int? month;
  BudgetStatus status;
  List<BudgetItem> items;
  DateTime createdAt;
  DateTime updatedAt;

  Budget({
    required this.id,
    required this.name,
    required this.year,
    this.month,
    this.status = BudgetStatus.draft,
    List<BudgetItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : items = items ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isYearly => month == null;
  BudgetType get type => isYearly ? BudgetType.yearly : BudgetType.monthly;

  double get totalPlanned => items.fold(0, (s, i) => s + i.plannedAmount);
  double get totalActual => items.fold(0, (s, i) => s + i.actualAmount);
  double get executionRate => totalPlanned > 0 ? totalActual / totalPlanned : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'year': year,
    'month': month,
    'status': status.name,
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'] as String,
    name: json['name'] as String,
    year: json['year'] as int,
    month: json['month'] as int?,
    status: BudgetStatus.values.byName(json['status'] as String? ?? 'draft'),
    items:
        (json['items'] as List?)
            ?.map((i) => BudgetItem.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

enum BudgetStatus { draft, active, closed }

enum BudgetType { yearly, monthly }

/// 预算科目明细
class BudgetItem {
  final String accountCodeId;
  String accountName;
  double plannedAmount;
  double actualAmount;

  BudgetItem({
    required this.accountCodeId,
    required this.accountName,
    this.plannedAmount = 0,
    this.actualAmount = 0,
  });

  double get executionRate =>
      plannedAmount > 0 ? actualAmount / plannedAmount : 0;

  Map<String, dynamic> toJson() => {
    'accountCodeId': accountCodeId,
    'accountName': accountName,
    'plannedAmount': plannedAmount,
    'actualAmount': actualAmount,
  };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
    accountCodeId: json['accountCodeId'] as String,
    accountName: json['accountName'] as String? ?? '',
    plannedAmount: (json['plannedAmount'] as num).toDouble(),
    actualAmount: (json['actualAmount'] as num).toDouble(),
  );
}

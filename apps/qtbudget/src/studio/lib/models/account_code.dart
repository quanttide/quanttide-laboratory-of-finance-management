/// 预算科目
class AccountCode {
  final String id;
  final String code;
  final String name;
  final String? parentId;
  final int level;
  final AccountType type;

  AccountCode({
    required this.id,
    required this.code,
    required this.name,
    this.parentId,
    this.level = 1,
    this.type = AccountType.expense,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'parentId': parentId,
    'level': level,
    'type': type.name,
  };

  factory AccountCode.fromJson(Map<String, dynamic> json) => AccountCode(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    parentId: json['parentId'] as String?,
    level: json['level'] as int? ?? 1,
    type: AccountType.values.byName(json['type'] as String? ?? 'expense'),
  );
}

enum AccountType { income, expense, asset, liability }

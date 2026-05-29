/// 事后分类标签。
///
/// 不参与预算编制和余额计算，仅用于流水的事后归类和对账。
/// 由用户自主增删改，无硬编码默认值。保留 code/parentId/level 字段
/// 以兼容会计科目表的扩展需求。
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

/// 标签类型：收入 / 支出 / 资产 / 负债。
enum AccountType { income, expense, asset, liability }

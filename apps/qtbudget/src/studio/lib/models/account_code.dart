class AccountCode {
  final String id;
  final String code;
  final String name;
  final AccountType type;

  const AccountCode({
    required this.id,
    required this.code,
    required this.name,
    this.type = AccountType.expense,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'type': type.name,
  };

  factory AccountCode.fromJson(Map<String, dynamic> json) => AccountCode(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    type: AccountType.values.byName(json['type'] as String? ?? 'expense'),
  );
}

enum AccountType { asset, liability, income, expense, equity }

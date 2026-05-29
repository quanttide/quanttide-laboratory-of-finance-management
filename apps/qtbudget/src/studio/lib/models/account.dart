import 'account_code.dart';
import 'journal_entry.dart';

/// 账户余额视图。
///
/// 根据科目类型计算正常余额方向：
/// - 资产/费用：正常余额在借方（debit - credit）
/// - 负债/收入/权益：正常余额在贷方（credit - debit）
class Account {
  final AccountCode code;
  double totalDebit;
  double totalCredit;

  Account({
    required this.code,
    this.totalDebit = 0,
    this.totalCredit = 0,
  });

  double get balance {
    return switch (code.type) {
      AccountType.asset || AccountType.expense => totalDebit - totalCredit,
      AccountType.liability || AccountType.income || AccountType.equity => totalCredit - totalDebit,
    };
  }

  void addEntry(JournalEntryLine line) {
    totalDebit += line.debit;
    totalCredit += line.credit;
  }

  static List<Account> fromEntries(
    List<AccountCode> codes,
    List<JournalEntry> entries,
  ) {
    final map = <String, Account>{};
    for (final code in codes) {
      map[code.id] = Account(code: code);
    }
    for (final entry in entries) {
      for (final line in entry.lines) {
        map.putIfAbsent(
          line.accountCodeId,
          () => Account(
            code: codes.firstWhere(
              (c) => c.id == line.accountCodeId,
              orElse: () => AccountCode(
                id: line.accountCodeId,
                code: line.accountCodeId,
                name: line.accountName.isNotEmpty ? line.accountName : line.accountCodeId,
              ),
            ),
          ),
        );
        map[line.accountCodeId]!.addEntry(line);
      }
    }
    return map.values.toList();
  }

  Map<String, dynamic> toJson() => {
    'codeId': code.id,
    'code': code.code,
    'name': code.name,
    'type': code.type.name,
    'totalDebit': totalDebit,
    'totalCredit': totalCredit,
    'balance': balance,
  };
}

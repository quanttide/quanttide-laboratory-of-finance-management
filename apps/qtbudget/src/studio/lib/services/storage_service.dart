import 'dart:convert';
import 'dart:html' as html;
import '../models/budget.dart';
import '../models/account_code.dart';
import '../models/transaction.dart';

/// localStorage 持久化服务
class StorageService {
  static const _budgetsKey = 'qtbudget_budgets';
  static const _codesKey = 'qtbudget_account_codes';
  static const _txnsKey = 'qtbudget_transactions';

  // ---- 预算科目 ----

  List<AccountCode> loadAccountCodes() {
    final raw = html.window.localStorage[_codesKey];
    if (raw == null) return _defaultAccountCodes();
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AccountCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void saveAccountCodes(List<AccountCode> codes) {
    html.window.localStorage[_codesKey] = jsonEncode(
      codes.map((c) => c.toJson()).toList(),
    );
  }

  List<AccountCode> _defaultAccountCodes() {
    final codes = [
      AccountCode(
        id: '1',
        code: 'A01',
        name: '办公费用',
        type: AccountType.expense,
      ),
      AccountCode(
        id: '2',
        code: 'A02',
        name: '差旅费用',
        type: AccountType.expense,
      ),
      AccountCode(
        id: '3',
        code: 'A03',
        name: '设备采购',
        type: AccountType.expense,
      ),
      AccountCode(
        id: '4',
        code: 'A04',
        name: '人力成本',
        type: AccountType.expense,
      ),
      AccountCode(id: '5', code: 'B01', name: '销售收入', type: AccountType.income),
      AccountCode(id: '6', code: 'B02', name: '服务收入', type: AccountType.income),
    ];
    saveAccountCodes(codes);
    return codes;
  }

  // ---- 预算 ----

  List<Budget> loadBudgets() {
    final raw = html.window.localStorage[_budgetsKey];
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
  }

  void saveBudgets(List<Budget> budgets) {
    html.window.localStorage[_budgetsKey] = jsonEncode(
      budgets.map((b) => b.toJson()).toList(),
    );
  }

  // ---- 收支记录 ----

  List<Transaction> loadTransactions() {
    final raw = html.window.localStorage[_txnsKey];
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void saveTransactions(List<Transaction> txns) {
    html.window.localStorage[_txnsKey] = jsonEncode(
      txns.map((t) => t.toJson()).toList(),
    );
  }
}

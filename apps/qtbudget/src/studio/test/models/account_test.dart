import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/account.dart';
import 'package:qtbudget/models/account_code.dart';
import 'package:qtbudget/models/journal_entry.dart';

void main() {
  group('Account', () {
    late AccountCode assetCode;
    late AccountCode expenseCode;
    late AccountCode liabilityCode;
    late AccountCode incomeCode;

    setUp(() {
      assetCode = AccountCode(id: '1001', code: '1001', name: '银行存款', type: AccountType.asset);
      expenseCode = AccountCode(id: '6602', code: '6602', name: '办公费', type: AccountType.expense);
      liabilityCode = AccountCode(id: '2001', code: '2001', name: '应付账款', type: AccountType.liability);
      incomeCode = AccountCode(id: '6101', code: '6101', name: '服务收入', type: AccountType.income);
    });

    test('asset normal balance is debit - credit', () {
      final a = Account(code: assetCode, totalDebit: 10000, totalCredit: 3000);
      expect(a.balance, 7000);
    });

    test('expense normal balance is debit - credit', () {
      final a = Account(code: expenseCode, totalDebit: 5000, totalCredit: 0);
      expect(a.balance, 5000);
    });

    test('liability normal balance is credit - debit', () {
      final a = Account(code: liabilityCode, totalDebit: 2000, totalCredit: 10000);
      expect(a.balance, 8000);
    });

    test('income normal balance is credit - debit', () {
      final a = Account(code: incomeCode, totalDebit: 0, totalCredit: 20000);
      expect(a.balance, 20000);
    });

    test('addEntry updates totals', () {
      final a = Account(code: assetCode);
      a.addEntry(JournalEntryLine(id: 'l1', accountCodeId: '1001', debit: 500, credit: 0));
      a.addEntry(JournalEntryLine(id: 'l2', accountCodeId: '1001', debit: 0, credit: 200));
      expect(a.totalDebit, 500);
      expect(a.totalCredit, 200);
      expect(a.balance, 300);
    });

    test('fromEntries aggregates multiple entries', () {
      final codes = [assetCode, expenseCode];
      final entries = [
        JournalEntry(
          id: 'je1', journalId: 'j1', entryDate: DateTime(2026, 1, 1),
          lines: [
            JournalEntryLine(id: 'l1', accountCodeId: '1001', debit: 0, credit: 1000),
            JournalEntryLine(id: 'l2', accountCodeId: '6602', debit: 1000, credit: 0),
          ],
        ),
        JournalEntry(
          id: 'je2', journalId: 'j1', entryDate: DateTime(2026, 1, 2),
          lines: [
            JournalEntryLine(id: 'l3', accountCodeId: '1001', debit: 500, credit: 0),
            JournalEntryLine(id: 'l4', accountCodeId: '6602', debit: 0, credit: 500),
          ],
        ),
      ];

      final accounts = Account.fromEntries(codes, entries);
      final bank = accounts.firstWhere((a) => a.code.id == '1001');
      final office = accounts.firstWhere((a) => a.code.id == '6602');

      expect(bank.totalDebit, 500);
      expect(bank.totalCredit, 1000);
      expect(bank.balance, -500); // 资产：500 - 1000 = -500（透支）

      expect(office.totalDebit, 1000);
      expect(office.totalCredit, 500);
      expect(office.balance, 500); // 费用：1000 - 500 = 500
    });
  });
}

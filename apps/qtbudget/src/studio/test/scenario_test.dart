import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';
import 'package:qtbudget/models/journal_entry.dart';
import 'package:qtbudget/services/storage_service.dart';
import 'shared/fake_storage.dart';

void main() {
  late StorageService storage;

  setUp(() {
    StorageService.useBackend(InMemoryStorageBackend());
    storage = StorageService();
  });

  test('完整场景：研发部备用金日记账', () {
    final journal = Journal(id: 'j_q3', name: '研发部备用金', startingBalance: 50000);
    storage.saveJournals([journal]);
    print('✓ 创建日记账：${journal.name}（期初 ¥${journal.startingBalance}）');

    final entries = [
      JournalEntry(
        id: 'je01', journalId: journal.id, entryDate: DateTime(2026, 7, 3),
        description: '打印纸和墨盒',
        lines: [
          JournalEntryLine(id: 'l01', accountCodeId: '6602', debit: 800, credit: 0, description: '办公费'),
          JournalEntryLine(id: 'l02', accountCodeId: '1001', debit: 0, credit: 800, description: '银行存款'),
        ],
      ),
      JournalEntry(
        id: 'je02', journalId: journal.id, entryDate: DateTime(2026, 7, 15),
        description: 'GPU 云服务器',
        lines: [
          JournalEntryLine(id: 'l03', accountCodeId: '6603', debit: 15000, credit: 0, description: '设备费'),
          JournalEntryLine(id: 'l04', accountCodeId: '1001', debit: 0, credit: 15000, description: '银行存款'),
        ],
      ),
      JournalEntry(
        id: 'je03', journalId: journal.id, entryDate: DateTime(2026, 8, 10),
        description: '二手设备转让',
        lines: [
          JournalEntryLine(id: 'l05', accountCodeId: '1001', debit: 2000, credit: 0, description: '银行存款'),
          JournalEntryLine(id: 'l06', accountCodeId: '6101', debit: 0, credit: 2000, description: '其他收入'),
        ],
      ),
    ];
    storage.saveEntries(entries);
    print('✓ 已录入 ${entries.length} 张凭证');

    final totalDebit = entries.fold(0.0, (s, e) => s + e.totalDebit);
    final totalCredit = entries.fold(0.0, (s, e) => s + e.totalCredit);
    final balance = (journal.startingBalance ?? 0) + totalDebit - totalCredit;

    print('\n========== 现金日记账 ==========');
    print('${journal.name}');
    print('期初余额：¥${journal.startingBalance?.toStringAsFixed(0)}');
    print('总借方：¥${totalDebit.toStringAsFixed(0)}');
    print('总贷方：¥${totalCredit.toStringAsFixed(0)}');
    print('当前余额：¥${balance.toStringAsFixed(0)}');
    print('===============================');

    expect(totalDebit, totalCredit);

    for (final e in entries) {
      expect(e.isBalanced, isTrue);
    }
    print('\n✓ 所有凭证借贷平衡 ✓');
  });
}

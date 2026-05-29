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
    final journal = Journal(id: 'j_q3', name: '研发部备用金');
    storage.saveJournals([journal]);

    // 简单流水模式：每笔分录只用一个方向
    // 借方 = 资金流入（收入、存入），贷方 = 资金流出（支出）
    final entries = [
      JournalEntry(
        id: 'je01', journalId: journal.id, description: '公司拨入备用金',
        lines: [JournalEntryLine(id: 'l01', type: LineType.debit, amount: 50000)],
      ),
      JournalEntry(
        id: 'je02', journalId: journal.id, description: 'GPU 云服务器',
        lines: [JournalEntryLine(id: 'l02', type: LineType.credit, amount: 15000)],
      ),
      JournalEntry(
        id: 'je03', journalId: journal.id, description: '二手设备转让收入',
        lines: [JournalEntryLine(id: 'l03', type: LineType.debit, amount: 2000)],
      ),
      JournalEntry(
        id: 'je04', journalId: journal.id, description: '购买办公用品',
        lines: [JournalEntryLine(id: 'l04', type: LineType.credit, amount: 1200)],
      ),
      // 复杂模式：多行借贷分录（财务人员用）
      JournalEntry(
        id: 'je05', journalId: journal.id, description: '员工报销差旅费',
        lines: [
          JournalEntryLine(id: 'l05', type: LineType.debit, amount: 3500),
          JournalEntryLine(id: 'l06', type: LineType.credit, amount: 3500),
        ],
      ),
    ];
    storage.saveEntries(entries);
    print('✓ 已录入 ${entries.length} 张凭证');

    // 余额 = 所有借方 - 所有贷方（简单模式不要求每笔平衡）
    final balance = entries.fold(0.0, (s, e) => s + e.totalDebit - e.totalCredit);
    print('\n当前余额：¥${balance.toStringAsFixed(0)}');
    expect(balance, 35800);
    print('\n✓ 余额 ¥${balance.toStringAsFixed(0)} ✓');
  });
}

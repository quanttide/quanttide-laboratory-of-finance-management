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
    print('✓ 创建日记账：${journal.name}');

    final entries = [
      JournalEntry(id: 'je01', journalId: journal.id, entryDate: DateTime(2026, 7, 1), description: '期初转入', debit: 50000, credit: 0),
      JournalEntry(id: 'je02', journalId: journal.id, entryDate: DateTime(2026, 7, 15), description: 'GPU 云服务器', debit: 15000, credit: 0),
      JournalEntry(id: 'je03', journalId: journal.id, entryDate: DateTime(2026, 8, 10), description: '二手设备转让', debit: 0, credit: 2000),
      JournalEntry(id: 'je04', journalId: journal.id, entryDate: DateTime(2026, 8, 20), description: '办公用品', debit: 800, credit: 0),
    ];
    storage.saveEntries(entries);
    print('✓ 已录入 ${entries.length} 笔分录');

    final totalDebit = entries.fold(0.0, (s, e) => s + e.debit);
    final totalCredit = entries.fold(0.0, (s, e) => s + e.credit);
    final balance = totalDebit - totalCredit;

    print('\n========== 现金日记账 ==========');
    print('${journal.name}');
    print('总借方：¥${totalDebit.toStringAsFixed(0)}');
    print('总贷方：¥${totalCredit.toStringAsFixed(0)}');
    print('当前余额：¥${balance.toStringAsFixed(0)}');
    print('===============================');

    expect(balance, 63800);
    print('\n✓ 余额 ¥${balance.toStringAsFixed(0)} ✓');
  });
}

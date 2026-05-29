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

  test('完整场景：办公室备用金日记账', () {
    final journal = Journal(id: 'j_q3', name: '研发部备用金', startingBalance: 50000);
    storage.saveJournals([journal]);
    print('✓ 创建日记账：${journal.name}（期初余额 ¥${journal.startingBalance}）');

    final entries = [
      JournalEntry(id: 'e01', journalId: journal.id, description: '打印纸和墨盒', income: 0, expense: 800, date: DateTime(2026, 7, 3)),
      JournalEntry(id: 'e02', journalId: journal.id, description: '团队聚餐', income: 0, expense: 1200, date: DateTime(2026, 7, 10)),
      JournalEntry(id: 'e03', journalId: journal.id, description: 'GPU 云服务器', income: 0, expense: 15000, date: DateTime(2026, 7, 15)),
      JournalEntry(id: 'e04', journalId: journal.id, description: '出差报销', income: 0, expense: 3500, date: DateTime(2026, 7, 18)),
      JournalEntry(id: 'e05', journalId: journal.id, description: 'License 年付', income: 0, expense: 12000, date: DateTime(2026, 8, 1)),
      JournalEntry(id: 'e06', journalId: journal.id, description: 'GPU 云服务器', income: 0, expense: 15000, date: DateTime(2026, 8, 15)),
      JournalEntry(id: 'e07', journalId: journal.id, description: '技术书籍', income: 0, expense: 600, date: DateTime(2026, 8, 20)),
      JournalEntry(id: 'e08', journalId: journal.id, description: 'GPU 云服务器', income: 0, expense: 15000, date: DateTime(2026, 9, 15)),
      JournalEntry(id: 'e09', journalId: journal.id, description: '二手设备转让', income: 2000, expense: 0, date: DateTime(2026, 8, 10)),
    ];
    storage.saveEntries(entries);
    print('✓ 已记录 ${entries.length} 笔流水');

    final totalInflow = entries.fold(0.0, (s, e) => s + e.income);
    final totalOutflow = entries.fold(0.0, (s, e) => s + e.expense);
    final balance = (journal.startingBalance ?? 0) + totalInflow - totalOutflow;

    print('\n========== 现金日记账 ==========');
    print('${journal.name}');
    print('期初余额：¥${journal.startingBalance?.toStringAsFixed(0) ?? '0'}');
    print('总收入：¥${totalInflow.toStringAsFixed(0)}');
    print('总支出：¥${totalOutflow.toStringAsFixed(0)}');
    print('当前余额：¥${balance.toStringAsFixed(0)}');
    print('===============================');

    expect(totalInflow, 2000);
    expect(totalOutflow, 63100);
    expect(balance, -11100);
    print('\n✓ 余额 ¥${balance.toStringAsFixed(0)}，注意控制支出 ✓');
  });
}

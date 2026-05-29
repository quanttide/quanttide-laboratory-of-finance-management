import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';
import 'package:qtbudget/models/entry.dart';
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
      Entry(id: 'e01', journalId: journal.id, description: '打印纸和墨盒', inflow: 0, outflow: 800, date: DateTime(2026, 7, 3)),
      Entry(id: 'e02', journalId: journal.id, description: '团队聚餐', inflow: 0, outflow: 1200, date: DateTime(2026, 7, 10)),
      Entry(id: 'e03', journalId: journal.id, description: 'GPU 云服务器', inflow: 0, outflow: 15000, date: DateTime(2026, 7, 15)),
      Entry(id: 'e04', journalId: journal.id, description: '出差报销', inflow: 0, outflow: 3500, date: DateTime(2026, 7, 18)),
      Entry(id: 'e05', journalId: journal.id, description: 'License 年付', inflow: 0, outflow: 12000, date: DateTime(2026, 8, 1)),
      Entry(id: 'e06', journalId: journal.id, description: 'GPU 云服务器', inflow: 0, outflow: 15000, date: DateTime(2026, 8, 15)),
      Entry(id: 'e07', journalId: journal.id, description: '技术书籍', inflow: 0, outflow: 600, date: DateTime(2026, 8, 20)),
      Entry(id: 'e08', journalId: journal.id, description: 'GPU 云服务器', inflow: 0, outflow: 15000, date: DateTime(2026, 9, 15)),
      Entry(id: 'e09', journalId: journal.id, description: '二手设备转让', inflow: 2000, outflow: 0, date: DateTime(2026, 8, 10)),
    ];
    storage.saveEntries(entries);
    print('✓ 已记录 ${entries.length} 笔流水');

    final totalInflow = entries.fold(0.0, (s, e) => s + e.inflow);
    final totalOutflow = entries.fold(0.0, (s, e) => s + e.outflow);
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

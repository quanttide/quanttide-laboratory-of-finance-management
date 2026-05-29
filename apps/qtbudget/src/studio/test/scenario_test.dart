import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/budget.dart';
import 'package:qtbudget/models/entry.dart';
import 'package:qtbudget/services/storage_service.dart';
import 'shared/fake_storage.dart';

/// 演示完整使用场景：研发部 Q3 运营经费管控
void main() {
  late StorageService storage;

  setUp(() {
    StorageService.useBackend(InMemoryStorageBackend());
    storage = StorageService();
  });

  test('完整场景：研发部 Q3 运营经费 10 万', () {
    final budget = Budget(id: 'b_q3', name: '研发部 Q3 运营经费', cap: 100000);
    storage.saveBudgets([budget]);
    print('✓ 预算创建完成：${budget.name}（总额 ¥${budget.cap}）');

    final entries = [
      Entry(id: 'e01', budgetId: budget.id, description: '打印纸和墨盒', amount: 800, date: DateTime(2026, 7, 3)),
      Entry(id: 'e02', budgetId: budget.id, description: '团队聚餐', amount: 1200, date: DateTime(2026, 7, 10)),
      Entry(id: 'e03', budgetId: budget.id, description: 'GPU 云服务器 7 月账单', amount: 15000, date: DateTime(2026, 7, 15)),
      Entry(id: 'e04', budgetId: budget.id, description: '上海出差高铁 + 住宿', amount: 3500, date: DateTime(2026, 7, 18)),
      Entry(id: 'e05', budgetId: budget.id, description: '研发工具 License（年付分摊）', amount: 12000, date: DateTime(2026, 8, 1)),
      Entry(id: 'e06', budgetId: budget.id, description: 'GPU 云服务器 8 月账单', amount: 15000, date: DateTime(2026, 8, 15)),
      Entry(id: 'e07', budgetId: budget.id, description: '技术书籍采购', amount: 600, date: DateTime(2026, 8, 20)),
      Entry(id: 'e08', budgetId: budget.id, description: 'GPU 云服务器 9 月账单', amount: 15000, date: DateTime(2026, 9, 15)),
      Entry(id: 'e09', budgetId: budget.id, description: '二手显示器', amount: -2000, date: DateTime(2026, 8, 10)),
    ];
    storage.saveEntries(entries);
    print('\n✓ 已记录 ${entries.length} 笔流水');

    final spent = entries.where((e) => e.isExpense).fold(0.0, (s, e) => s + e.amount);
    final income = entries.where((e) => e.isIncome).fold(0.0, (s, e) => s + e.amount.abs());
    final remaining = budget.cap - spent + income;
    final dates = entries.map((e) => e.date).toList()..sort();
    final days = dates.first.difference(dates.last).inDays.abs() + 1;
    final burnRate = spent / days;

    print('\n========== 预算看板 ==========');
    print('预算：${budget.name}');
    print('总额度：¥${budget.cap}');
    print('已花费：¥${spent.toStringAsFixed(0)}（${(spent / budget.cap * 100).toStringAsFixed(0)}%）');
    print('已回款：¥${income.toStringAsFixed(0)}');
    print('净支出：¥${(spent - income).toStringAsFixed(0)}');
    print('剩余：¥${remaining.toStringAsFixed(0)}');
    print('日均消耗：¥${burnRate.toStringAsFixed(0)}');
    print('预计可花天数：${(remaining / burnRate).round()} 天');
    print('==============================');

    expect(spent, 63100);
    expect(income, 2000);
    expect(remaining, 38900);
    print('\n✓ 剩余 ¥${remaining.toStringAsFixed(0)}，预算仍在控制中 ✓');
  });
}

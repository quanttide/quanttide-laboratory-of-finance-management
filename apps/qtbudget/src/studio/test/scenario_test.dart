import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/budget.dart';
import 'package:qtbudget/models/transaction.dart';
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
    // ===== 第一阶段：创建预算 =====
    // 老板说 Q3 最多花 10 万，设个额度就行
    final budget = Budget(
      id: 'b_q3',
      name: '研发部 Q3 运营经费',
      cap: 100000,
      note: '老板批的 Q3 额度，含设备采购和日常开销',
    );
    storage.saveBudgets([budget]);
    print('✓ 预算创建完成：${budget.name}');
    print('  总额度：¥${budget.cap}');

    // ===== 第二阶段：日常花销（一笔笔花，不看科目） =====
    final txns = [
      Transaction(
        id: 'tx_01', budgetId: budget.id,
        description: '打印纸和墨盒', amount: 800,
        date: DateTime(2026, 7, 3),
      ),
      Transaction(
        id: 'tx_02', budgetId: budget.id,
        description: '团队聚餐', amount: 1200,
        date: DateTime(2026, 7, 10),
      ),
      Transaction(
        id: 'tx_03', budgetId: budget.id,
        description: 'GPU 云服务器 7 月账单', amount: 15000,
        date: DateTime(2026, 7, 15),
      ),
      Transaction(
        id: 'tx_04', budgetId: budget.id,
        description: '上海出差高铁 + 住宿', amount: 3500,
        date: DateTime(2026, 7, 18),
      ),
      Transaction(
        id: 'tx_05', budgetId: budget.id,
        description: '研发工具 License（年付分摊）', amount: 12000,
        date: DateTime(2026, 8, 1),
      ),
      Transaction(
        id: 'tx_06', budgetId: budget.id,
        description: 'GPU 云服务器 8 月账单', amount: 15000,
        date: DateTime(2026, 8, 15),
      ),
      Transaction(
        id: 'tx_07', budgetId: budget.id,
        description: '技术书籍采购', amount: 600,
        date: DateTime(2026, 8, 20),
      ),
      Transaction(
        id: 'tx_08', budgetId: budget.id,
        description: 'GPU 云服务器 9 月账单', amount: 15000,
        date: DateTime(2026, 9, 15),
      ),
    ];
    storage.saveTransactions(txns);
    print('\n✓ 已记录 ${txns.length} 笔支出（共 ¥${txns.fold(0.0, (s, t) => s + t.amount)}）');
    for (final t in txns) {
      print('  ${t.date.toString().substring(0, 10)} -¥${t.amount}  ${t.description}');
    }

    // ===== 第三阶段：看余额和消耗 =====
    final spent = txns.fold(0.0, (s, t) => s + t.amount);
    final remaining = budget.cap - spent;
    final days = txns.map((t) => t.date).reduce(
      (a, b) => a.isBefore(b) ? a : b,
    ).difference(txns.map((t) => t.date).reduce(
      (a, b) => a.isAfter(b) ? a : b,
    )).inDays.abs() + 1;
    final burnRate = spent / days;

    print('\n========== 预算看板 ==========');
    print('预算：${budget.name}');
    print('总额度：¥${budget.cap}');
    print('已花费：¥${spent.toStringAsFixed(0)}（${(spent / budget.cap * 100).toStringAsFixed(0)}%）');
    print('剩余：¥${remaining.toStringAsFixed(0)}');
    print('日均消耗：¥${burnRate.toStringAsFixed(0)}');
    print('预计可花天数：${(remaining / burnRate).round()} 天');
    print('==============================');

    // ===== 验证 =====
    expect(spent, 63100);
    expect(remaining, 36900);
    expect(burnRate, closeTo(841, 1));
    print('\n✓ 剩余 ¥${remaining.toStringAsFixed(0)}，预算仍在控制中 ✓');
  });
}

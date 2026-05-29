import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/budget.dart';
import 'package:qtbudget/models/transaction.dart';
import 'package:qtbudget/services/storage_service.dart';
import '../shared/fake_storage.dart';

void main() {
  late InMemoryStorageBackend backend;
  late StorageService service;

  setUp(() {
    backend = InMemoryStorageBackend();
    StorageService.useBackend(backend);
    service = StorageService();
  });

  group('Budgets', () {
    test('load returns empty list when none saved', () {
      expect(service.loadBudgets(), isEmpty);
    });

    test('save and load round-trip', () {
      final budgets = [
        Budget(id: 'b1', name: 'Q3 经费', cap: 100000, note: '季度预算'),
      ];
      service.saveBudgets(budgets);
      final loaded = service.loadBudgets();
      expect(loaded.length, 1);
      expect(loaded[0].name, 'Q3 经费');
      expect(loaded[0].cap, 100000);
      expect(loaded[0].note, '季度预算');
    });

    test('multiple budgets are persisted', () {
      service.saveBudgets([
        Budget(id: 'b1', name: '经费A', cap: 50000),
        Budget(id: 'b2', name: '经费B', cap: 30000),
      ]);
      expect(service.loadBudgets().length, 2);
    });
  });

  group('Transactions', () {
    test('load returns empty list when none saved', () {
      expect(service.loadTransactions(), isEmpty);
    });

    test('save and load round-trip', () {
      final txns = [
        Transaction(
          id: 'tx1',
          budgetId: 'b1',
          description: '买书',
          amount: 200,
          date: DateTime(2026, 5, 29),
        ),
      ];
      service.saveTransactions(txns);
      final loaded = service.loadTransactions();
      expect(loaded.length, 1);
      expect(loaded[0].description, '买书');
      expect(loaded[0].type, TransactionType.expense);
    });

    test('save transaction with tag', () {
      service.saveTransactions([
        Transaction(
          id: 'tx1', budgetId: 'b1', description: 'test',
          amount: 100, date: DateTime(2026, 5, 29), tagId: 't1',
        ),
      ]);
      expect(service.loadTransactions().first.tagId, 't1');
    });
  });

  group('Cross-entity isolation', () {
    test('saving budgets does not affect transactions', () {
      service.saveBudgets([Budget(id: 'b1', name: '预算', cap: 10000)]);
      service.saveTransactions([
        Transaction(
          id: 'tx1', budgetId: 'b1', description: 'test', amount: 100,
          date: DateTime(2026, 5, 29),
        ),
      ]);

      expect(service.loadBudgets().length, 1);
      expect(service.loadTransactions().length, 1);

      service.saveBudgets([]);
      expect(service.loadBudgets(), isEmpty);
      expect(service.loadTransactions().length, 1);
    });
  });
}

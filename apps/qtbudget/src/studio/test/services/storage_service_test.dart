import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/budget.dart';
import 'package:qtbudget/models/entry.dart';
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
      service.saveBudgets([
        Budget(id: 'b1', name: 'Q3 经费', cap: 100000, note: '季度预算'),
      ]);
      final loaded = service.loadBudgets();
      expect(loaded.length, 1);
      expect(loaded[0].cap, 100000);
    });

    test('multiple budgets are persisted', () {
      service.saveBudgets([
        Budget(id: 'b1', name: '经费A', cap: 50000),
        Budget(id: 'b2', name: '经费B', cap: 30000),
      ]);
      expect(service.loadBudgets().length, 2);
    });
  });

  group('Entries', () {
    test('load returns empty list when none saved', () {
      expect(service.loadEntries(), isEmpty);
    });

    test('save and load round-trip', () {
      service.saveEntries([
        Entry(id: 'e1', budgetId: 'b1', description: '买书', amount: 200, date: DateTime(2026, 5, 29)),
      ]);
      final loaded = service.loadEntries();
      expect(loaded.length, 1);
      expect(loaded[0].description, '买书');
    });

    test('save entry with tag', () {
      service.saveEntries([
        Entry(id: 'e1', budgetId: 'b1', description: 'test', amount: 100, date: DateTime(2026, 5, 29), tagId: 't1'),
      ]);
      expect(service.loadEntries().first.tagId, 't1');
    });
  });

  group('Cross-entity isolation', () {
    test('saving budgets does not affect entries', () {
      service.saveBudgets([Budget(id: 'b1', name: '预算', cap: 10000)]);
      service.saveEntries([
        Entry(id: 'e1', budgetId: 'b1', description: 'test', amount: 100, date: DateTime(2026, 5, 29)),
      ]);

      expect(service.loadBudgets().length, 1);
      expect(service.loadEntries().length, 1);

      service.saveBudgets([]);
      expect(service.loadBudgets(), isEmpty);
      expect(service.loadEntries().length, 1);
    });
  });
}

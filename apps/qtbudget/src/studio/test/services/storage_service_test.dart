import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';
import 'package:qtbudget/models/journal_entry.dart';
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

  group('Journals', () {
    test('load returns empty when none saved', () {
      expect(service.loadJournals(), isEmpty);
    });

    test('save and load round-trip', () {
      service.saveJournals([Journal(id: 'j1', name: '备用金', startingBalance: 5000)]);
      final loaded = service.loadJournals();
      expect(loaded.first.name, '备用金');
      expect(loaded.first.startingBalance, 5000);
    });
  });

  group('Entries', () {
    test('load returns empty when none saved', () {
      expect(service.loadEntries(), isEmpty);
    });

    test('save and load round-trip', () {
      service.saveEntries([
        JournalEntry(id: 'e1', journalId: 'j1', description: '买书', income: 0, expense: 200, date: DateTime(2026, 5, 29)),
      ]);
      expect(service.loadEntries().first.expense, 200);
    });
  });
}

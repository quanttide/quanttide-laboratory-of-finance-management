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
      service.saveJournals([Journal(id: 'j1', name: '备用金')]);
      expect(service.loadJournals().first.name, '备用金');
    });
  });

  group('JournalEntries', () {
    test('load returns empty when none saved', () {
      expect(service.loadEntries(), isEmpty);
    });

    test('save and load with lines', () {
      service.saveEntries([
        JournalEntry(id: 'je1', journalId: 'j1', entryDate: DateTime(2026, 5, 29), lines: [
          JournalEntryLine(id: 'l1', debit: 500, credit: 0),
          JournalEntryLine(id: 'l2', debit: 0, credit: 500),
        ]),
      ]);
      expect(service.loadEntries().first.lines.length, 2);
    });
  });
}

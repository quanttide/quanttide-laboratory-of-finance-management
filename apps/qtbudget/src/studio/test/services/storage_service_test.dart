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

  test('journals save and load', () {
    service.saveJournals([Journal(id: 'j1', name: '备用金')]);
    expect(service.loadJournals().first.name, '备用金');
  });

  test('entries save and load', () {
    service.saveEntries([
      JournalEntry(id: 'je1', journalId: 'j1', entryDate: DateTime(2026, 5, 29), debit: 500, credit: 0),
    ]);
    expect(service.loadEntries().first.debit, 500);
  });
}

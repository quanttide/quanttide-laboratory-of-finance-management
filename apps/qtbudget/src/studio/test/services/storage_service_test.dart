import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';
import 'package:qtbudget/models/journal_entry.dart';
import 'package:qtbudget/services/storage_service.dart';
import '../shared/fake_storage.dart';

double debit(JournalEntry e) => e.lines.where((l) => l.type == LineType.debit).fold(0.0, (s, l) => s + l.amount);
double credit(JournalEntry e) => e.lines.where((l) => l.type == LineType.credit).fold(0.0, (s, l) => s + l.amount);

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

  test('entries save and load with lines', () {
    service.saveEntries([
      JournalEntry(id: 'je1', journalId: 'j1', lines: [
        JournalEntryLine(id: 'l1', type: LineType.debit, amount: 500),
        JournalEntryLine(id: 'l2', type: LineType.credit, amount: 500),
      ]),
    ]);
    final loaded = service.loadEntries().first;
    expect(loaded.lines.length, 2);
    expect(debit(loaded), credit(loaded));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:quanttide_finance/quanttide_finance.dart';
import 'package:qtbudget/services/storage_service.dart';
import '../shared/fake_storage.dart';

double debit(JournalEntry e) => e.lines.where((l) => l.type == LineType.debit).fold(0.0, (s, l) => s + l.amount);
double credit(JournalEntry e) => e.lines.where((l) => l.type == LineType.credit).fold(0.0, (s, l) => s + l.amount);

void main() {
  late InMemoryStorageBackend backend;
  late StorageService service;
  final now = DateTime(2026, 5, 29);

  setUp(() {
    backend = InMemoryStorageBackend();
    StorageService.useBackend(backend);
    service = StorageService();
  });

  test('journals save and load', () {
    service.saveJournals([Journal(id: 'j1', name: '备用金', createdAt: now)]);
    expect(service.loadJournals().first.name, '备用金');
  });

  test('entries save and load with lines', () {
    service.saveEntries([
      JournalEntry(id: 'je1', journalId: 'j1', createdAt: now, lines: [
        JournalEntryLine(id: 'l1', type: LineType.debit, amount: 500, createdAt: now),
        JournalEntryLine(id: 'l2', type: LineType.credit, amount: 500, createdAt: now),
      ]),
    ]);
    final loaded = service.loadEntries().first;
    expect(loaded.lines.length, 2);
    expect(debit(loaded), credit(loaded));
  });
}

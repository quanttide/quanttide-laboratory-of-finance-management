import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';
import 'package:qtbudget/models/journal_entry.dart';
import 'package:qtbudget/models/account_code.dart';
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

  group('AccountCodes', () {
    test('load returns empty when none saved', () {
      expect(service.loadAccountCodes(), isEmpty);
    });

    test('save and load round-trip', () {
      service.saveAccountCodes([
        AccountCode(id: 'c1', code: '1001', name: '银行存款', type: AccountType.asset),
      ]);
      expect(service.loadAccountCodes().first.code, '1001');
    });
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
        JournalEntry(
          id: 'je1', journalId: 'j1', entryDate: DateTime(2026, 5, 29),
          lines: [
            JournalEntryLine(id: 'l1', accountCodeId: '6602', debit: 500, credit: 0),
            JournalEntryLine(id: 'l2', accountCodeId: '1001', debit: 0, credit: 500),
          ],
        ),
      ]);
      final loaded = service.loadEntries();
      expect(loaded.first.lines.length, 2);
      expect(loaded.first.totalDebit, 500);
    });
  });
}

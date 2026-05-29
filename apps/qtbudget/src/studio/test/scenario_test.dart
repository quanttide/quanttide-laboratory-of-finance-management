import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';
import 'package:qtbudget/models/journal_entry.dart';
import 'package:qtbudget/services/storage_service.dart';
import 'shared/fake_storage.dart';

double debit(JournalEntry e) => e.lines.where((l) => l.type == LineType.debit).fold(0.0, (s, l) => s + l.amount);
double credit(JournalEntry e) => e.lines.where((l) => l.type == LineType.credit).fold(0.0, (s, l) => s + l.amount);

void main() {
  late StorageService storage;

  setUp(() {
    StorageService.useBackend(InMemoryStorageBackend());
    storage = StorageService();
  });

  test('完整场景：研发部备用金日记账', () {
    final journal = Journal(id: 'j_q3', name: '研发部备用金');
    storage.saveJournals([journal]);

    final entries = [
      JournalEntry(id: 'je01', journalId: journal.id, description: '公司拨入备用金',
        lines: [JournalEntryLine(id: 'l01', type: LineType.debit, amount: 50000)]),
      JournalEntry(id: 'je02', journalId: journal.id, description: 'GPU 云服务器',
        lines: [JournalEntryLine(id: 'l02', type: LineType.credit, amount: 15000)]),
      JournalEntry(id: 'je03', journalId: journal.id, description: '二手设备转让收入',
        lines: [JournalEntryLine(id: 'l03', type: LineType.debit, amount: 2000)]),
      JournalEntry(id: 'je04', journalId: journal.id, description: '购买办公用品',
        lines: [JournalEntryLine(id: 'l04', type: LineType.credit, amount: 1200)]),
      JournalEntry(id: 'je05', journalId: journal.id, description: '员工报销差旅费',
        lines: [
          JournalEntryLine(id: 'l05', type: LineType.debit, amount: 3500),
          JournalEntryLine(id: 'l06', type: LineType.credit, amount: 3500),
        ]),
    ];
    storage.saveEntries(entries);

    final balance = entries.fold(0.0, (s, e) => s + debit(e) - credit(e));
    expect(balance, 35800);
  });
}

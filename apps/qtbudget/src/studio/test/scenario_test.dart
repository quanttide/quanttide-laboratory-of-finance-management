import 'package:flutter_test/flutter_test.dart';
import 'package:quanttide_finance/quanttide_finance.dart';
import 'package:qtbudget/services/storage_service.dart';
import 'shared/fake_storage.dart';

double debit(JournalEntry e) => e.lines.where((l) => l.type == LineType.debit).fold(0.0, (s, l) => s + l.amount);
double credit(JournalEntry e) => e.lines.where((l) => l.type == LineType.credit).fold(0.0, (s, l) => s + l.amount);

void main() {
  late StorageService storage;
  final now = DateTime(2026, 7, 1);

  setUp(() {
    StorageService.useBackend(InMemoryStorageBackend());
    storage = StorageService();
  });

  test('完整场景：研发部备用金日记账', () {
    final journal = Journal(id: 'j_q3', name: '研发部备用金', createdAt: now);
    storage.saveJournals([journal]);

    final entries = [
      JournalEntry(id: 'je01', journalId: journal.id, createdAt: now, description: '公司拨入备用金',
        lines: [JournalEntryLine(id: 'l01', type: LineType.debit, amount: 50000, createdAt: now)]),
      JournalEntry(id: 'je02', journalId: journal.id, createdAt: now, description: 'GPU 云服务器',
        lines: [JournalEntryLine(id: 'l02', type: LineType.credit, amount: 15000, createdAt: now)]),
      JournalEntry(id: 'je03', journalId: journal.id, createdAt: now, description: '二手设备转让收入',
        lines: [JournalEntryLine(id: 'l03', type: LineType.debit, amount: 2000, createdAt: now)]),
      JournalEntry(id: 'je04', journalId: journal.id, createdAt: now, description: '购买办公用品',
        lines: [JournalEntryLine(id: 'l04', type: LineType.credit, amount: 1200, createdAt: now)]),
      JournalEntry(id: 'je05', journalId: journal.id, createdAt: now, description: '员工报销差旅费',
        lines: [
          JournalEntryLine(id: 'l05', type: LineType.debit, amount: 3500, createdAt: now),
          JournalEntryLine(id: 'l06', type: LineType.credit, amount: 3500, createdAt: now),
        ]),
    ];
    storage.saveEntries(entries);

    final balance = entries.fold(0.0, (s, e) => s + debit(e) - credit(e));
    expect(balance, 35800);
  });
}

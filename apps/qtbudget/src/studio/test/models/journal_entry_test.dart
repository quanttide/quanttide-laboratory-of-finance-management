import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal_entry.dart';

void main() {
  group('JournalEntryLine', () {
    test('toJson / fromJson round-trip', () {
      final l = JournalEntryLine(
        id: 'l1', type: LineType.debit, amount: 1000, description: '买纸',
      );
      final json = l.toJson();
      final restored = JournalEntryLine.fromJson(json);
      expect(restored.type, LineType.debit);
      expect(restored.amount, 1000);
      expect(restored.createdAt, isA<DateTime>());
    });

    test('assert rejects negative amount', () {
      expect(
        () => JournalEntryLine(id: 'l1', type: LineType.debit, amount: -1),
        throwsAssertionError,
      );
    });
  });

  group('JournalEntry', () {
    final now = DateTime(2026, 5, 29);

    test('toJson / fromJson round-trip', () {
      final e = JournalEntry(
        id: 'je1', journalId: 'j1',
        description: '购买办公用品', createdAt: now,
        lines: [
          JournalEntryLine(id: 'l1', type: LineType.debit, amount: 1200),
          JournalEntryLine(id: 'l2', type: LineType.credit, amount: 1200),
        ],
      );
      final json = e.toJson();
      final restored = JournalEntry.fromJson(json);
      expect(restored.lines.length, 2);
      expect(restored.totalDebit, 1200);
      expect(restored.totalCredit, 1200);
      expect(restored.isBalanced, isTrue);
    });

    test('isBalanced false when not balanced', () {
      final e = JournalEntry(id: 'je2', journalId: 'j1', createdAt: now, lines: [
        JournalEntryLine(id: 'l1', type: LineType.debit, amount: 100),
      ]);
      expect(e.isBalanced, isFalse);
    });

    test('default createdAt', () {
      expect(JournalEntry(id: 'je3', journalId: 'j1').createdAt, isA<DateTime>());
    });
  });
}

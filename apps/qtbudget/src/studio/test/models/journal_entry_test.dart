import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal_entry.dart';

void main() {
  group('JournalEntryLine', () {
    test('toJson / fromJson round-trip', () {
      final l = JournalEntryLine(
        id: 'l1', accountCodeId: '1001', accountName: '银行存款',
        debit: 1000, credit: 0, description: '存入',
      );
      final json = l.toJson();
      final restored = JournalEntryLine.fromJson(json);
      expect(restored.debit, 1000);
      expect(restored.credit, 0);
      expect(restored.accountName, '银行存款');
    });
  });

  group('JournalEntry', () {
    final now = DateTime(2026, 5, 29);

    test('toJson / fromJson round-trip', () {
      final e = JournalEntry(
        id: 'je1', journalId: 'j1', entryDate: now,
        description: '购买办公用品',
        lines: [
          JournalEntryLine(id: 'l1', accountCodeId: '6602', debit: 1200, credit: 0, description: '办公费'),
          JournalEntryLine(id: 'l2', accountCodeId: '1001', debit: 0, credit: 1200, description: '银行存款'),
        ],
      );
      final json = e.toJson();
      final restored = JournalEntry.fromJson(json);

      expect(restored.id, 'je1');
      expect(restored.lines.length, 2);
      expect(restored.totalDebit, 1200);
      expect(restored.totalCredit, 1200);
      expect(restored.isBalanced, isTrue);
    });

    test('isBalanced returns false when not balanced', () {
      final e = JournalEntry(
        id: 'je2', journalId: 'j1', entryDate: now,
        lines: [
          JournalEntryLine(id: 'l1', accountCodeId: '6602', debit: 100, credit: 0),
        ],
      );
      expect(e.isBalanced, isFalse);
    });

    test('isBalanced returns false when all zero', () {
      final e = JournalEntry(
        id: 'je3', journalId: 'j1', entryDate: now,
        lines: [
          JournalEntryLine(id: 'l1', accountCodeId: '6602', debit: 0, credit: 0),
        ],
      );
      expect(e.isBalanced, isFalse);
    });

    test('status defaults to draft', () {
      final e = JournalEntry(id: 'je4', journalId: 'j1', entryDate: now);
      expect(e.status, EntryStatus.draft);
    });

    test('default lines is empty list', () {
      final e = JournalEntry(id: 'je5', journalId: 'j1', entryDate: now);
      expect(e.lines, isEmpty);
    });

    test('fromJson handles null lines', () {
      final json = {
        'id': 'je6', 'journalId': 'j1',
        'entryDate': now.toIso8601String(),
        'description': 'test',
        'status': 'draft',
      };
      expect(JournalEntry.fromJson(json).lines, isEmpty);
    });
  });
}

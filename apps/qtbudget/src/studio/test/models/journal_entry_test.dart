import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal_entry.dart';

void main() {
  group('JournalEntry', () {
    final now = DateTime(2026, 5, 29);

    test('toJson / fromJson round-trip for expense', () {
      final e = JournalEntry(
        id: 'e1', journalId: 'j1', description: '买书',
        income: 0, expense: 200, date: now,
      );
      final json = e.toJson();
      final restored = JournalEntry.fromJson(json);

      expect(restored.id, e.id);
      expect(restored.journalId, e.journalId);
      expect(restored.description, e.description);
      expect(restored.income, e.income);
      expect(restored.expense, e.expense);
      expect(restored.date.toIso8601String(), e.date.toIso8601String());
      expect(restored.amount, -200);
    });

    test('toJson / fromJson round-trip for income', () {
      final e = JournalEntry(
        id: 'e2', journalId: 'j1', description: '回款',
        income: 5000, expense: 0, date: now,
      );
      expect(JournalEntry.fromJson(e.toJson()).amount, 5000);
    });

    test('fromJson defaults missing numeric fields to 0', () {
      final json = {
        'id': 'e3', 'journalId': 'j1',
        'description': 'test',
        'date': now.toIso8601String(),
      };
      final e = JournalEntry.fromJson(json);
      expect(e.income, 0);
      expect(e.expense, 0);
      expect(e.description, 'test');
    });

    test('amount returns income - expense', () {
      expect(JournalEntry(id: 'e1', journalId: 'j1', description: 'a', income: 100, expense: 30, date: now).amount, 70);
      expect(JournalEntry(id: 'e2', journalId: 'j1', description: 'a', income: 0, expense: 50, date: now).amount, -50);
    });

    test('assert rejects negative values', () {
      expect(
        () => JournalEntry(id: 'e1', journalId: 'j1', description: 'a', income: -1, expense: 0, date: now),
        throwsAssertionError,
      );
    });
  });
}

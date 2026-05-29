import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal_entry.dart';

void main() {
  final now = DateTime(2026, 5, 29);

  test('toJson / fromJson round-trip', () {
    final e = JournalEntry(
      id: 'je1', journalId: 'j1', entryDate: now,
      description: '购买办公用品', debit: 1200, credit: 0,
    );
    final json = e.toJson();
    final restored = JournalEntry.fromJson(json);
    expect(restored.debit, 1200);
    expect(restored.credit, 0);
    expect(restored.description, '购买办公用品');
    expect(restored.amount, 1200);
  });

  test('amount returns debit - credit', () {
    expect(JournalEntry(id: 'je1', journalId: 'j1', entryDate: now, debit: 100, credit: 30).amount, 70);
    expect(JournalEntry(id: 'je2', journalId: 'j1', entryDate: now, debit: 0, credit: 50).amount, -50);
  });

  test('fromJson defaults missing fields', () {
    final json = {'id': 'je3', 'journalId': 'j1', 'entryDate': now.toIso8601String()};
    final e = JournalEntry.fromJson(json);
    expect(e.description, '');
    expect(e.debit, 0);
    expect(e.credit, 0);
  });

  test('assert rejects negative values', () {
    expect(
      () => JournalEntry(id: 'je4', journalId: 'j1', entryDate: now, debit: -1, credit: 0),
      throwsAssertionError,
    );
  });
}

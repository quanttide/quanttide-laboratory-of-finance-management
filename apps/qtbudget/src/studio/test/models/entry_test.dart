import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/entry.dart';

void main() {
  group('Entry', () {
    final now = DateTime(2026, 5, 29, 10, 30);

    test('toJson / fromJson round-trip for expense', () {
      final e = Entry(
        id: 'e1',
        budgetId: 'b1',
        description: '买书',
        amount: 200,
        date: now,
      );
      final json = e.toJson();
      final restored = Entry.fromJson(json);

      expect(restored.id, e.id);
      expect(restored.budgetId, e.budgetId);
      expect(restored.description, e.description);
      expect(restored.amount, e.amount);
      expect(restored.date.toIso8601String(), e.date.toIso8601String());
      expect(restored.tagId, isNull);
      expect(restored.isExpense, isTrue);
      expect(restored.isIncome, isFalse);
    });

    test('toJson / fromJson with negative amount (income)', () {
      final e = Entry(
        id: 'e2',
        budgetId: 'b1',
        description: '回款',
        amount: -5000,
        date: now,
      );
      final json = e.toJson();
      final restored = Entry.fromJson(json);

      expect(restored.amount, -5000);
      expect(restored.isIncome, isTrue);
      expect(restored.isExpense, isFalse);
    });

    test('toJson / fromJson with tag', () {
      final e = Entry(
        id: 'e3', budgetId: 'b1',
        description: '外卖', amount: 50,
        date: now, tagId: 't1',
      );
      final json = e.toJson();
      expect(Entry.fromJson(json).tagId, 't1');
    });

    test('fromJson defaults missing fields', () {
      final json = {
        'id': 'e4',
        'budgetId': 'b1',
        'amount': 100,
        'date': now.toIso8601String(),
      };
      final e = Entry.fromJson(json);
      expect(e.description, '');
      expect(e.tagId, isNull);
    });
  });
}

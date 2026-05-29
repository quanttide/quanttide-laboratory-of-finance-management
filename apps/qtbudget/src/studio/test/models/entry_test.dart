import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/entry.dart';

void main() {
  group('Entry', () {
    final now = DateTime(2026, 5, 29, 10, 30);

    test('toJson / fromJson round-trip for expense', () {
      final e = Entry(
        id: 'e1', budgetId: 'b1', description: '买书', amount: 200, date: now,
      );
      final json = e.toJson();
      final restored = Entry.fromJson(json);

      expect(restored.id, e.id);
      expect(restored.budgetId, e.budgetId);
      expect(restored.description, e.description);
      expect(restored.amount, e.amount);
      expect(restored.date.toIso8601String(), e.date.toIso8601String());
      expect(restored.isExpense, isTrue);
      expect(restored.isIncome, isFalse);
    });

    test('negative amount is income', () {
      final e = Entry(
        id: 'e2', budgetId: 'b1', description: '回款', amount: -5000, date: now,
      );
      expect(e.isIncome, isTrue);
      expect(e.isExpense, isFalse);
    });

    test('fromJson defaults missing description', () {
      final json = {
        'id': 'e3', 'budgetId': 'b1', 'amount': 100,
        'date': now.toIso8601String(),
      };
      expect(Entry.fromJson(json).description, '');
    });
  });
}

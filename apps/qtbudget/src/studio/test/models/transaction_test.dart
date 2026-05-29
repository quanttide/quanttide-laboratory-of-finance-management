import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/transaction.dart';

void main() {
  group('Transaction', () {
    final now = DateTime(2026, 5, 29, 10, 30);

    test('toJson / fromJson round-trip for expense', () {
      final txn = Transaction(
        id: 'tx1',
        budgetId: 'b1',
        description: '购买办公用品',
        amount: 500,
        date: now,
        type: TransactionType.expense,
      );
      final json = txn.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored.id, txn.id);
      expect(restored.budgetId, txn.budgetId);
      expect(restored.description, txn.description);
      expect(restored.amount, txn.amount);
      expect(restored.date.toIso8601String(), txn.date.toIso8601String());
      expect(restored.type, txn.type);
      expect(restored.tagId, isNull);
    });

    test('toJson / fromJson with tag', () {
      final txn = Transaction(
        id: 'tx2',
        budgetId: 'b1',
        description: '外卖',
        amount: 50,
        date: now,
        tagId: 't1',
      );
      final json = txn.toJson();
      final restored = Transaction.fromJson(json);
      expect(restored.tagId, 't1');
    });

    test('defaults type to expense', () {
      final txn = Transaction(
        id: 'tx3',
        budgetId: 'b1',
        description: 'test',
        amount: 100,
        date: now,
      );
      expect(txn.type, TransactionType.expense);
    });

    test('fromJson defaults missing fields', () {
      final json = {
        'id': 'tx4',
        'budgetId': 'b1',
        'amount': 100,
        'date': now.toIso8601String(),
      };
      final txn = Transaction.fromJson(json);
      expect(txn.description, '');
      expect(txn.type, TransactionType.expense);
      expect(txn.tagId, isNull);
    });
  });
}

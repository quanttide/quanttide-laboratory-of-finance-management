import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/budget.dart';

void main() {
  group('Budget', () {
    final now = DateTime(2026, 5, 29);

    test('toJson / fromJson round-trip', () {
      final b = Budget(
        id: 'b1', name: 'Q3 经费', cap: 100000, note: '季度预算', createdAt: now,
      );
      final json = b.toJson();
      final restored = Budget.fromJson(json);

      expect(restored.id, b.id);
      expect(restored.name, b.name);
      expect(restored.cap, b.cap);
      expect(restored.note, b.note);
      expect(restored.createdAt.toIso8601String(), b.createdAt.toIso8601String());
    });

    test('fromJson handles missing note', () {
      final json = {
        'id': 'b1', 'name': 'test', 'cap': 50000,
        'createdAt': now.toIso8601String(),
      };
      expect(Budget.fromJson(json).note, isNull);
    });

    test('fromJson handles cap as int', () {
      final json = {
        'id': 'b1', 'name': 'test', 'cap': 10000,
        'createdAt': now.toIso8601String(),
      };
      expect(Budget.fromJson(json).cap, 10000.0);
    });

    test('default createdAt is set', () {
      expect(Budget(id: 'b1', name: 'test', cap: 1000).createdAt, isA<DateTime>());
    });
  });
}

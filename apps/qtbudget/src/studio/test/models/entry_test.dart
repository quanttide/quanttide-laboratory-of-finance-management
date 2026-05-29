import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/entry.dart';

void main() {
  group('Entry', () {
    final now = DateTime(2026, 5, 29);

    test('toJson / fromJson round-trip for outflow', () {
      final e = Entry(
        id: 'e1', journalId: 'j1', description: '买书',
        inflow: 0, outflow: 200, date: now,
      );
      final json = e.toJson();
      final restored = Entry.fromJson(json);

      expect(restored.id, e.id);
      expect(restored.journalId, e.journalId);
      expect(restored.description, e.description);
      expect(restored.inflow, e.inflow);
      expect(restored.outflow, e.outflow);
      expect(restored.date.toIso8601String(), e.date.toIso8601String());
      expect(restored.amount, -200);
    });

    test('toJson / fromJson round-trip for inflow', () {
      final e = Entry(
        id: 'e2', journalId: 'j1', description: '回款',
        inflow: 5000, outflow: 0, date: now,
      );
      expect(Entry.fromJson(e.toJson()).amount, 5000);
    });

    test('fromJson defaults missing numeric fields to 0', () {
      final json = {
        'id': 'e3', 'journalId': 'j1',
        'description': 'test',
        'date': now.toIso8601String(),
      };
      final e = Entry.fromJson(json);
      expect(e.inflow, 0);
      expect(e.outflow, 0);
      expect(e.description, 'test');
    });

    test('amount returns inflow - outflow', () {
      expect(Entry(id: 'e1', journalId: 'j1', description: 'a', inflow: 100, outflow: 30, date: now).amount, 70);
      expect(Entry(id: 'e2', journalId: 'j1', description: 'a', inflow: 0, outflow: 50, date: now).amount, -50);
    });

    test('assert rejects negative values', () {
      expect(
        () => Entry(id: 'e1', journalId: 'j1', description: 'a', inflow: -1, outflow: 0, date: now),
        throwsAssertionError,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';

void main() {
  group('Journal', () {
    final now = DateTime(2026, 5, 29);

    test('toJson / fromJson round-trip', () {
      final j = Journal(
        id: 'j1', name: '备用金', startingBalance: 5000, createdAt: now,
      );
      final json = j.toJson();
      final restored = Journal.fromJson(json);

      expect(restored.id, j.id);
      expect(restored.name, j.name);
      expect(restored.startingBalance, j.startingBalance);
      expect(restored.createdAt.toIso8601String(), j.createdAt.toIso8601String());
    });

    test('fromJson handles null startingBalance', () {
      final json = {'id': 'j1', 'name': 'test', 'createdAt': now.toIso8601String()};
      expect(Journal.fromJson(json).startingBalance, isNull);
    });
  });
}

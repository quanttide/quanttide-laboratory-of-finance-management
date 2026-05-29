import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/models/journal.dart';

void main() {
  final now = DateTime(2026, 5, 29);

  test('toJson / fromJson round-trip', () {
    final j = Journal(id: 'j1', name: '备用金', createdAt: now);
    final json = j.toJson();
    final restored = Journal.fromJson(json);
    expect(restored.id, j.id);
    expect(restored.name, j.name);
    expect(restored.createdAt.toIso8601String(), j.createdAt.toIso8601String());
  });

  test('default createdAt is set', () {
    expect(Journal(id: 'j1', name: 'test').createdAt, isA<DateTime>());
  });
}

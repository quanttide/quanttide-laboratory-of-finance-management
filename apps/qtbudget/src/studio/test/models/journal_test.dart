import 'package:flutter_test/flutter_test.dart';
import 'package:quanttide_finance/quanttide_finance.dart';

void main() {
  final now = DateTime(2026, 5, 29);

  test('toJson / fromJson round-trip', () {
    final j = Journal(id: 'j1', name: '备用金', createdAt: now);
    final json = j.toJson();
    final restored = Journal.fromJson(json);
    expect(restored.id, j.id);
    expect(restored.name, j.name);
    expect(restored.createdAt, now);
  });

  test('copyWith', () {
    final j = Journal(id: 'j1', name: '备用金', createdAt: now);
    final j2 = j.copyWith(name: '改名的备用金');
    expect(j2.name, '改名的备用金');
    expect(j2.id, 'j1');
  });
}

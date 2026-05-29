import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/app.dart';
import 'package:qtbudget/services/storage_service.dart';
import 'shared/fake_storage.dart';

void main() {
  setUp(() {
    StorageService.useBackend(InMemoryStorageBackend());
  });

  testWidgets('renders dashboard with empty state', (tester) async {
    await tester.pumpWidget(const QtBudgetApp());
    await tester.pumpAndSettle();

    expect(find.text('现金日记账'), findsOneWidget);
    expect(find.text('暂无日记账，点击右上角 + 创建'), findsOneWidget);
  });

  testWidgets('tap + opens journal form', (tester) async {
    await tester.pumpWidget(const QtBudgetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('新建日记账'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('can fill journal form and save', (tester) async {
    await tester.pumpWidget(const QtBudgetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '办公室备用金');
    await tester.enterText(find.byType(TextField).at(1), '50000');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('办公室备用金'), findsOneWidget);
  });
}

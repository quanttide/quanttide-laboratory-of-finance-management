import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtbudget/app.dart';
import 'package:qtbudget/services/storage_service.dart';
import 'shared/fake_storage.dart';

void main() {
  setUp(() {
    StorageService.useBackend(InMemoryStorageBackend());
  });

  testWidgets('app renders dashboard with empty state', (tester) async {
    await tester.pumpWidget(const QtBudgetApp());
    await tester.pumpAndSettle();

    expect(find.text('量潮预算管家'), findsOneWidget);
    expect(find.text('暂无预算，点击右上角 + 创建'), findsOneWidget);
  });

  testWidgets('tap + opens budget form page', (tester) async {
    await tester.pumpWidget(const QtBudgetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('新建预算'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('can fill budget form and save', (tester) async {
    await tester.pumpWidget(const QtBudgetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // fill name
    await tester.enterText(find.byType(TextField).at(0), 'Q3 经费');
    // fill cap
    await tester.enterText(find.byType(TextField).at(1), '100000');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('Q3 经费'), findsOneWidget);
  });
}

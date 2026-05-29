import 'dart:convert';
import '../models/budget.dart';
import '../models/entry.dart';
import 'storage_backend.dart';

class StorageService {
  static StorageBackend _backend = _NoOpBackend();

  static StorageBackend get backend => _backend;

  static void useBackend(StorageBackend backend) {
    _backend = backend;
  }

  static const _budgetsKey = 'qtbudget_budgets';
  static const _entriesKey = 'qtbudget_entries';

  List<Budget> loadBudgets() {
    final raw = _backend.getItem(_budgetsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
  }

  void saveBudgets(List<Budget> budgets) {
    _backend.setItem(
      _budgetsKey,
      jsonEncode(budgets.map((b) => b.toJson()).toList()),
    );
  }

  List<Entry> loadEntries() {
    final raw = _backend.getItem(_entriesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Entry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void saveEntries(List<Entry> entries) {
    _backend.setItem(
      _entriesKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

class _NoOpBackend implements StorageBackend {
  @override
  String? getItem(String key) => null;

  @override
  void setItem(String key, String value) {}
}

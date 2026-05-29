import 'dart:convert';
import '../models/journal.dart';
import '../models/journal_entry.dart';
import '../models/account_code.dart';
import 'storage_backend.dart';

class StorageService {
  static StorageBackend _backend = _NoOpBackend();

  static void useBackend(StorageBackend backend) {
    _backend = backend;
  }

  static const _journalsKey = 'qtbudget_journals';
  static const _entriesKey = 'qtbudget_entries';
  static const _codesKey = 'qtbudget_account_codes';

  List<Journal> loadJournals() {
    final raw = _backend.getItem(_journalsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Journal.fromJson(e as Map<String, dynamic>)).toList();
  }

  void saveJournals(List<Journal> journals) {
    _backend.setItem(_journalsKey, jsonEncode(journals.map((j) => j.toJson()).toList()));
  }

  List<JournalEntry> loadEntries() {
    final raw = _backend.getItem(_entriesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  void saveEntries(List<JournalEntry> entries) {
    _backend.setItem(_entriesKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  List<AccountCode> loadAccountCodes() {
    final raw = _backend.getItem(_codesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => AccountCode.fromJson(e as Map<String, dynamic>)).toList();
  }

  void saveAccountCodes(List<AccountCode> codes) {
    _backend.setItem(_codesKey, jsonEncode(codes.map((c) => c.toJson()).toList()));
  }
}

class _NoOpBackend implements StorageBackend {
  @override
  String? getItem(String key) => null;
  @override
  void setItem(String key, String value) {}
}

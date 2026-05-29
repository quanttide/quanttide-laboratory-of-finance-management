import 'package:qtbudget/services/storage_backend.dart';

class InMemoryStorageBackend implements StorageBackend {
  final _store = <String, String>{};

  @override
  String? getItem(String key) => _store[key];

  @override
  void setItem(String key, String value) {
    _store[key] = value;
  }
}

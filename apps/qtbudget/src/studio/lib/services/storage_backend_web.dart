import 'package:web/web.dart';
import 'storage_backend.dart';

class LocalStorageBackend implements StorageBackend {
  @override
  String? getItem(String key) => window.localStorage.getItem(key);

  @override
  void setItem(String key, String value) =>
      window.localStorage.setItem(key, value);
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps FlutterSecureStorage to isolate the JWT lifecycle.
/// Using the OS keychain means the token survives app restarts but is
/// wiped on uninstall — the correct security boundary for a field operator.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kTokenKey = 'mineguard_jwt';

  Future<void> save(String token) => _storage.write(key: _kTokenKey, value: token);

  Future<String?> read() => _storage.read(key: _kTokenKey);

  Future<void> delete() => _storage.delete(key: _kTokenKey);
}

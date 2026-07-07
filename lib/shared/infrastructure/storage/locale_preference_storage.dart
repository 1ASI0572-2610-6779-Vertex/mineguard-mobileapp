import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the user's chosen language code across sessions using the same
/// secure-storage mechanism `TokenStorage` already uses — no new storage
/// dependency.
class LocalePreferenceStorage {
  LocalePreferenceStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kLocaleKey = 'mineguard_locale';

  Future<void> save(String languageCode) =>
      _storage.write(key: _kLocaleKey, value: languageCode);

  Future<String?> read() => _storage.read(key: _kLocaleKey);
}

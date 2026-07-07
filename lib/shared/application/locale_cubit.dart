import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../infrastructure/storage/locale_preference_storage.dart';

/// Cross-cutting "current locale" state, provided once at the app root —
/// same pattern as `SessionCubit`. Defaults to English; `loadSavedLocale()`
/// is called once in `main()` before `runApp` so the very first frame
/// already reflects any persisted choice, with no flicker.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._storage) : super(const Locale('en'));

  final LocalePreferenceStorage _storage;

  Future<void> loadSavedLocale() async {
    final saved = await _storage.read();
    if (saved != null) emit(Locale(saved));
  }

  Future<void> changeLocale(Locale locale) async {
    emit(locale);
    await _storage.save(locale.languageCode);
  }
}

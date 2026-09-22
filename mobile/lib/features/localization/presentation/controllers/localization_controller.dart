import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class LocalizationController extends ChangeNotifier {
  Locale _currentLocale = const Locale('as'); // Assamese default

  Locale get currentLocale => _currentLocale;
  bool get isRtl => AppLocalizations.isRtl(_currentLocale);

  void setLocale(Locale newLocale) {
    if (_currentLocale.languageCode != newLocale.languageCode) {
      _currentLocale = newLocale;
      notifyListeners();
    }
  }

  void setLanguageCode(String languageCode) {
    setLocale(Locale(languageCode));
  }
}

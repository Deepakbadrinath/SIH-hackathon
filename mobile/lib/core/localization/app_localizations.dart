import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};
  Map<String, dynamic>? _metadata;

  AppLocalizations(this.locale, [Map<String, String>? initialStrings, Map<String, dynamic>? metadata]) {
    if (initialStrings != null) {
      _localizedStrings = initialStrings;
    }
    _metadata = metadata;
  }

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  static const LocalizationsDelegate<MaterialLocalizations> fallbackMaterialDelegate =
      _FallbackMaterialLocalizationsDelegate();
  static const LocalizationsDelegate<CupertinoLocalizations> fallbackCupertinoDelegate =
      _FallbackCupertinoLocalizationsDelegate();

  /// Standard delegates for SmritiSetu, including regional fallbacks for locales
  /// like Manipuri (mni) which are not built into Flutter's default GlobalMaterialLocalizations.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    fallbackMaterialDelegate,
    fallbackCupertinoDelegate,
  ];

  /// 21 supported languages across Indian regional families and international extensions:
  /// Regional & National: English (en), Hindi (hi), Assamese (as), Manipuri (mni), Bengali (bn),
  /// Odia (or), Telugu (te), Tamil (ta), Kannada (kn), Malayalam (ml), Marathi (mr),
  /// Gujarati (gu), Punjabi (pa), Urdu (ur).
  /// International Extensions: Spanish (es), French (fr), German (de), Arabic (ar),
  /// Chinese (zh), Japanese (ja), Korean (ko).
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('hi', ''), // Hindi
    Locale('as', ''), // Assamese
    Locale('mni', ''), // Manipuri (Meitei)
    Locale('bn', ''), // Bengali
    Locale('or', ''), // Odia
    Locale('te', ''), // Telugu
    Locale('ta', ''), // Tamil
    Locale('kn', ''), // Kannada
    Locale('ml', ''), // Malayalam
    Locale('mr', ''), // Marathi
    Locale('gu', ''), // Gujarati
    Locale('pa', ''), // Punjabi
    Locale('ur', ''), // Urdu (RTL)
    Locale('es', ''), // Spanish (International)
    Locale('fr', ''), // French (International)
    Locale('de', ''), // German (International)
    Locale('ar', ''), // Arabic (RTL International)
    Locale('zh', ''), // Chinese (CJK International)
    Locale('ja', ''), // Japanese (CJK International)
    Locale('ko', ''), // Korean (CJK International)
  ];

  /// Checks whether a given locale requires Right-to-Left (RTL) text direction.
  static bool isRtl(Locale locale) {
    return locale.languageCode == 'ur' || locale.languageCode == 'ar';
  }

  /// Metadata associated with the translation file (e.g. human review flag)
  Map<String, dynamic>? get metadata => _metadata;

  /// Returns true if this translation resource requires human clinical/linguistic review
  bool get isHumanReviewRequired => _metadata?['status'] == 'human_review_required';

  /// Loads the localization resource JSON file for the given locale.
  Future<bool> load() async {
    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    } catch (_) {
      // Fallback to English if regional file is not found
      jsonString = await rootBundle.loadString('assets/i18n/en.json');
    }

    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    
    if (jsonMap.containsKey('_metadata') && jsonMap['_metadata'] is Map<String, dynamic>) {
      _metadata = jsonMap['_metadata'] as Map<String, dynamic>;
    }

    _localizedStrings = {};
    _flattenJson(jsonMap, '');
    return true;
  }

  void _flattenJson(Map<String, dynamic> map, String prefix) {
    map.forEach((key, value) {
      if (key == '_metadata') return;
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _flattenJson(value, fullKey);
      } else {
        _localizedStrings[fullKey] = value.toString();
      }
    });
  }

  /// Translates a key with optional dynamic argument replacement.
  /// Example: translate('welcome.user', args: {'name': 'Dadu'})
  String translate(String key, {Map<String, dynamic>? args}) {
    String res = _localizedStrings[key] ?? key;
    if (args != null && args.isNotEmpty) {
      args.forEach((k, v) {
        res = res.replaceAll('{$k}', v.toString());
      });
    }
    return res;
  }

  /// Translates a plural key based on count.
  /// Looks for key.zero, key.one, key.other, with fallback to key.
  String translatePlural(String key, int count, {Map<String, dynamic>? args}) {
    final mergedArgs = <String, dynamic>{
      'count': formatNumber(count),
      ...?args,
    };

    if (count == 0 && _localizedStrings.containsKey('$key.zero')) {
      return translate('$key.zero', args: mergedArgs);
    } else if (count == 1 && _localizedStrings.containsKey('$key.one')) {
      return translate('$key.one', args: mergedArgs);
    } else if (_localizedStrings.containsKey('$key.other')) {
      return translate('$key.other', args: mergedArgs);
    }
    return translate(key, args: mergedArgs);
  }

  /// Formats a number, optionally converting to native script digits.
  String formatNumber(num value, {bool useNativeDigits = false}) {
    final str = value.toString();
    if (!useNativeDigits) return str;
    return _convertDigits(str, locale.languageCode);
  }

  /// Formats a date using localized month name.
  String formatDate(DateTime date, {bool includeWeekday = false}) {
    final dayStr = formatNumber(date.day);
    final yearStr = formatNumber(date.year);
    final monthKey = 'date.month.${date.month}';
    final monthStr = _localizedStrings.containsKey(monthKey) ? translate(monthKey) : _defaultMonth(date.month);

    if (includeWeekday) {
      final weekdayKey = 'date.weekday.${date.weekday}';
      final weekdayStr = _localizedStrings.containsKey(weekdayKey) ? translate(weekdayKey) : '';
      return '$weekdayStr, $dayStr $monthStr $yearStr';
    }
    return '$dayStr $monthStr $yearStr';
  }

  /// Formats a TimeOfDay in localized 12-hour format.
  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final periodKey = time.period == DayPeriod.am ? 'time.am' : 'time.pm';
    final periodStr = _localizedStrings.containsKey(periodKey)
        ? translate(periodKey)
        : (time.period == DayPeriod.am ? 'AM' : 'PM');
    return '$hour:$minute $periodStr';
  }

  /// Accessibility label retrieval helper.
  String getAccessibilityLabel(String key, {String? defaultFallback, Map<String, dynamic>? args}) {
    final accessKey = 'accessibility.$key';
    if (_localizedStrings.containsKey(accessKey)) {
      return translate(accessKey, args: args);
    }
    if (_localizedStrings.containsKey(key)) {
      return translate(key, args: args);
    }
    return defaultFallback ?? key;
  }

  String _defaultMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  static String _convertDigits(String input, String langCode) {
    const digitMaps = {
      'as': ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'],
      'bn': ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'],
      'hi': ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'],
      'mr': ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'],
      'or': ['୦', '୧', '୨', '୩', '୪', '୫', '୬', '୭', '୮', '୯'],
      'gu': ['૦', '૧', '૨', '૩', '૪', '૫', '૬', '૭', '૮', '૯'],
      'pa': ['੦', '੧', '੨', '੩', '੪', '੫', '੬', '੭', '੮', '੯'],
      'te': ['౦', '౧', '౨', '౩', '౪', '౫', '౬', '౭', '౮', '౯'],
      'ta': ['௦', '௧', '௨', '௩', '௪', '௫', '௬', '௭', '௮', '௯'],
      'kn': ['೦', '೧', '೨', '೩', '೪', '೫', '೬', '೭', '೮', '೯'],
      'ml': ['൦', '൧', '൨', '൩', '൪', '൫', '൬', '൭', '൮', '൯'],
      'ur': ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'],
      'ar': ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'],
    };

    final map = digitMaps[langCode];
    if (map == null) return input;

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final codeUnit = char.codeUnitAt(0);
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.write(map[codeUnit - 48]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class _FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) => DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

class _FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}

extension AppLocalizationsContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

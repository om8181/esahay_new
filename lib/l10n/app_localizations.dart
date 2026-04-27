import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
        context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login': 'Login',
      'username': 'Username',
      'password': 'Password',
      'language_question': 'Which language are you comfortable with?',
      'continue': 'Continue',
      'need_help': 'Need Help?',
    },
    'hi': {
      'login': 'लॉगिन',
      'username': 'उपयोगकर्ता नाम',
      'password': 'पासवर्ड',
      'language_question': 'आप किस भाषा में सहज हैं?',
      'continue': 'आगे बढ़ें',
      'need_help': 'मदद चाहिए?',
    },
    'mr': {
      'login': 'लॉगिन',
      'username': 'वापरकर्तानाव',
      'password': 'पासवर्ड',
      'language_question': 'तुम्हाला कोणती भाषा सोयीची आहे?',
      'continue': 'पुढे जा',
      'need_help': 'मदत हवी आहे?',
    },
  };

  String text(String key) {
    return _localizedValues[locale.languageCode]![key]!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_) => false;
}

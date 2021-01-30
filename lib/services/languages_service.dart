class LanguageService {
  static final List<String> supportedLanguages = ['en', 'de', 'tr', 'sr', 'ro', 'sk', 'bs', 'hr', 'hu'];
  static final String defaultLanguage = 'en';

  static String getLang(String lang) {
    if (supportedLanguages.contains(lang))
      return lang;
    return defaultLanguage;
  }
}
enum AppLocale {
  en,
  zhHans,
  zhHant,
}

extension AppLocaleLabels on AppLocale {
  String get menuLabel => switch (this) {
        AppLocale.en => 'EN',
        AppLocale.zhHans => '简',
        AppLocale.zhHant => '繁',
      };

  String get displayName => switch (this) {
        AppLocale.en => 'English',
        AppLocale.zhHans => '简体中文',
        AppLocale.zhHant => '繁體中文',
      };
}

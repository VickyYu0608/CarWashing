import 'package:car_washing_app/l10n/app_locale.dart';
import 'package:car_washing_app/l10n/app_strings.dart';
import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  AppLocale _locale = AppLocale.zhHans;

  AppLocale get appLocale => _locale;

  Locale get flutterLocale => switch (_locale) {
        AppLocale.en => const Locale('en'),
        AppLocale.zhHans => const Locale('zh', 'CN'),
        AppLocale.zhHant => const Locale('zh', 'TW'),
      };

  AppStrings get strings => AppStrings(_locale);

  void setLocale(AppLocale locale) {
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    AppStrings.current = strings;
    notifyListeners();
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  LocaleScope({
    required LocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller) {
    _activeController = controller;
    AppStrings.current = controller.strings;
  }

  static LocaleController? _activeController;

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!.notifier!;
  }

  static AppStrings stringsOf(BuildContext context) => of(context).strings;
}

extension L10nContext on BuildContext {
  AppStrings get s => LocaleScope.stringsOf(this);
}

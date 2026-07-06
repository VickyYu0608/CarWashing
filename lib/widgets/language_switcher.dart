import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/app_locale.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

/// Globe-style language switcher: EN / 繁 / 简
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    this.iconColor,
    this.iconSize = 24,
    super.key,
  });

  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final locale = controller.appLocale;
        return PopupMenuButton<AppLocale>(
          tooltip: context.s.languageTitle,
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: controller.setLocale,
          itemBuilder: (context) => [
            for (final option in AppLocale.values)
              PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (option == locale)
                      const Icon(Icons.check, size: 18, color: AppColors.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(
                      option.menuLabel,
                      style: TextStyle(
                        fontWeight:
                            option == locale ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option.displayName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Icon(
              Icons.language,
              size: iconSize,
              color: iconColor ?? Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Compact variant for light backgrounds (logged-in pages)
class LanguageSwitcherLight extends StatelessWidget {
  const LanguageSwitcherLight({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final locale = controller.appLocale;
        return PopupMenuButton<AppLocale>(
          tooltip: context.s.languageTitle,
          onSelected: controller.setLocale,
          itemBuilder: (context) => [
            for (final option in AppLocale.values)
              PopupMenuItem(
                value: option,
                child: Text(
                  '${option.menuLabel} · ${option.displayName}',
                  style: TextStyle(
                    fontWeight:
                        option == locale ? FontWeight.w800 : FontWeight.normal,
                  ),
                ),
              ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.language, color: AppColors.primary),
          ),
        );
      },
    );
  }
}

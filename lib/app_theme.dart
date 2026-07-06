import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:car_washing_app/widgets/ui_motion.dart';

/// 清洗到家 · 蓝白品牌色
class AppColors {
  static const primary = Color(0xFF1D6FE8);
  static const primaryDark = Color(0xFF1456C4);
  static const primaryLight = Color(0xFF4DA3FF);
  static const primarySurface = Color(0xFFE8F2FF);
  static const background = Color(0xFFF3F7FD);
  static const cardBorder = Color(0xFFDCE7F5);
  static const textPrimary = Color(0xFF1A2B4A);
  static const textSecondary = Color(0xFF5C6F8C);
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySurface,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.primaryLight,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD6EBFF),
    onSecondaryContainer: AppColors.primaryDark,
    tertiary: Color(0xFF38BDF8),
    onTertiary: Colors.white,
    error: Color(0xFFE53935),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.cardBorder,
    shadow: Color(0x331D6FE8),
    surfaceContainerHighest: Color(0xFFEEF4FB),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 12,
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primarySurface,
      shadowColor: const Color(0x331D6FE8),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        );
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder,
      space: 24,
      thickness: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySurface,
      labelStyle: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.primary,
      textColor: AppColors.textPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.primaryDark,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: buildAppPageTransitionsTheme(),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: AppColors.textSecondary, height: 1.45),
      bodySmall: TextStyle(color: AppColors.textSecondary, height: 1.4),
    ),
  );
}

BoxDecoration appGradientHeaderDecoration({double radius = 20}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryLight],
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(
        color: Color(0x331D6FE8),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );
}

BoxDecoration appSurfaceCardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.cardBorder),
    boxShadow: const [
      BoxShadow(
        color: Color(0x141D6FE8),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Color(0x141D6FE8),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x401D6FE8),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.local_car_wash_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    this.size = 44,
    super.key,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.5),
    );
  }
}

/// Extra scroll inset so center-docked scan FAB does not cover list tails.
const double kUserShellFabClearance = 56;

/// Bottom bar with a center notch for the scan FAB (avoids covering nav labels).
class UserDockedBottomNav extends StatelessWidget {
  const UserDockedBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    assert(destinations.length == 4, 'UserDockedBottomNav expects 4 tabs');
    return Material(
      elevation: 8,
      shadowColor: const Color(0x141D6FE8),
      color: Colors.white,
      child: BottomAppBar(
        height: 64,
        padding: EdgeInsets.zero,
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(
              child: _DockedNavItem(
                destination: destinations[0],
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
            ),
            Expanded(
              child: _DockedNavItem(
                destination: destinations[1],
                selected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
            ),
            const SizedBox(width: 76),
            Expanded(
              child: _DockedNavItem(
                destination: destinations[2],
                selected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
            ),
            Expanded(
              child: _DockedNavItem(
                destination: destinations[3],
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockedNavItem extends StatefulWidget {
  const _DockedNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DockedNavItem> createState() => _DockedNavItemState();
}

class _DockedNavItemState extends State<_DockedNavItem> {
  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: widget.selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: IconTheme(
                data: IconThemeData(color: color, size: 24),
                child: widget.selected
                    ? (widget.destination.selectedIcon ?? widget.destination.icon)
                    : widget.destination.icon,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(
                widget.destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

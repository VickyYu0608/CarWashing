import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/widgets/ui_motion.dart';
import 'package:flutter/material.dart';

/// Consistent elevated surface used across list cards and panels.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: appSurfaceCardDecoration(),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return card;
    }
    return AppPressable(onTap: onTap, child: card);
  }
}

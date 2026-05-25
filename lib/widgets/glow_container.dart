import 'package:flutter/material.dart';

enum GlowType { none, primary, tertiary, error }

class GlowContainer extends StatelessWidget {
  final Widget child;
  final GlowType glowType;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowType = GlowType.none,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    List<BoxShadow>? shadows;
    final theme = Theme.of(context);

    switch (glowType) {
      case GlowType.primary:
        shadows = [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
          )
        ];
        break;
      case GlowType.tertiary:
        shadows = [
          BoxShadow(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          )
        ];
        break;
      case GlowType.error:
        shadows = [
          BoxShadow(
            color: theme.colorScheme.error.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 0,
          )
        ];
        break;
      default:
        shadows = null;
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}

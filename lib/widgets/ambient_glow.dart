import 'package:flutter/material.dart';
import 'dart:ui';

class AmbientGlow extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final double sigmaX;
  final double sigmaY;
  final Color color;

  const AmbientGlow({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.size = 384,
    this.sigmaX = 120,
    this.sigmaY = 120,
    required this.color,
  });

  factory AmbientGlow.primary({
    Key? key,
    double? top,
    double? left,
    double? right,
    double? bottom,
    double size = 384,
    double sigmaX = 120,
    double sigmaY = 120,
    double alpha = 0.1,
    required BuildContext context,
  }) {
    return AmbientGlow(
      key: key,
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      size: size,
      sigmaX: sigmaX,
      sigmaY: sigmaY,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: alpha),
    );
  }

  factory AmbientGlow.tertiary({
    Key? key,
    double? top,
    double? left,
    double? right,
    double? bottom,
    double size = 384,
    double sigmaX = 100,
    double sigmaY = 100,
    double alpha = 0.05,
    required BuildContext context,
  }) {
    return AmbientGlow(
      key: key,
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      size: size,
      sigmaX: sigmaX,
      sigmaY: sigmaY,
      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: alpha),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

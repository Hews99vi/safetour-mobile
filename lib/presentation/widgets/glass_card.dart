import 'package:flutter/material.dart';

import '../../core/theme/app_glass.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return AppGlass(
      padding: padding,
      shadowColor: shadowColor,
      child: child,
    );
  }
}

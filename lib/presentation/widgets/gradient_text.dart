import 'package:flutter/material.dart';

import '../../core/constants/app_gradients.dart';

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AppGradients.accent,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: (style ?? Theme.of(context).textTheme.titleMedium)
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

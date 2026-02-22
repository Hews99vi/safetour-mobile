import 'package:flutter/material.dart';

class Responsive {
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1200;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 24);
    }
    if (width >= tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  }
}

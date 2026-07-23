import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

class AdaptiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? desktopXL;

  const AdaptiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
    this.desktopXL,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= AppBreakpoints.desktopXLMin && desktopXL != null) {
          return desktopXL!;
        }
        if (width >= AppBreakpoints.desktopMin && desktop != null) {
          return desktop!;
        }
        if (width >= AppBreakpoints.tabletMin && tablet != null) {
          return tablet!;
        }
        return phone;
      },
    );
  }
}

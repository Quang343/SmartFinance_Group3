import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

class ResponsiveSpacing {
  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.desktopMin) {
      return const EdgeInsets.all(28.0);
    } else if (width >= AppBreakpoints.tabletMin) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0);
    }
  }

  static double pagePaddingValue(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.desktopMin) return 28.0;
    if (width >= AppBreakpoints.tabletMin) return 20.0;
    return 14.0;
  }

  static double cardGap(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.desktopMin) return 16.0;
    if (width >= AppBreakpoints.tabletMin) return 12.0;
    return 10.0;
  }

  static double sectionGap(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.desktopMin) return 24.0;
    if (width >= AppBreakpoints.tabletMin) return 18.0;
    return 14.0;
  }

  static double cardBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.desktopMin) return 16.0;
    return 14.0;
  }
}

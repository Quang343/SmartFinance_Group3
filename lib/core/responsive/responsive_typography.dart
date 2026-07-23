import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

class ResponsiveTypography {
  static TextStyle titleLarge(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final width = MediaQuery.of(context).size.width;
    double size = 20.0;
    if (width >= AppBreakpoints.desktopXLMin) {
      size = 26.0;
    } else if (width >= AppBreakpoints.desktopMin) {
      size = 24.0;
    } else if (width >= AppBreakpoints.tabletMin) {
      size = 22.0;
    }

    return TextStyle(
      fontSize: size,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle titleMedium(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final width = MediaQuery.of(context).size.width;
    double size = 16.0;
    if (width >= AppBreakpoints.desktopMin) {
      size = 18.0;
    } else if (width >= AppBreakpoints.tabletMin) {
      size = 17.0;
    }

    return TextStyle(
      fontSize: size,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color,
    );
  }

  static TextStyle body(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final width = MediaQuery.of(context).size.width;
    double size = 13.5;
    if (width >= AppBreakpoints.desktopMin) {
      size = 15.0;
    } else if (width >= AppBreakpoints.tabletMin) {
      size = 14.0;
    }

    return TextStyle(
      fontSize: size,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final width = MediaQuery.of(context).size.width;
    double size = 11.5;
    if (width >= AppBreakpoints.desktopMin) {
      size = 13.0;
    } else if (width >= AppBreakpoints.tabletMin) {
      size = 12.0;
    }

    return TextStyle(
      fontSize: size,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  static TextStyle amount(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final width = MediaQuery.of(context).size.width;
    double size = 15.0;
    if (width >= AppBreakpoints.desktopXLMin) {
      size = 19.0;
    } else if (width >= AppBreakpoints.desktopMin) {
      size = 17.5;
    } else if (width >= AppBreakpoints.tabletMin) {
      size = 16.0;
    }

    return TextStyle(
      fontSize: size,
      fontWeight: fontWeight ?? FontWeight.w800,
      color: color,
    );
  }
}

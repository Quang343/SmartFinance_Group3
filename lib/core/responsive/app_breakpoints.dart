import 'package:flutter/material.dart';

enum DeviceType {
  phone,
  tablet,
  desktop,
  desktopXL,
}

class AppBreakpoints {
  static const double phoneMax = 599.0;
  static const double tabletMin = 600.0;
  static const double tabletMax = 999.0;
  static const double desktopMin = 1000.0;
  static const double desktopMax = 1399.0;
  static const double desktopXLMin = 1400.0;

  static DeviceType getDeviceType(double width) {
    if (width >= desktopXLMin) return DeviceType.desktopXL;
    if (width >= desktopMin) return DeviceType.desktop;
    if (width >= tabletMin) return DeviceType.tablet;
    return DeviceType.phone;
  }

  static DeviceType of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getDeviceType(width);
  }

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletMin;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= tabletMin && w < desktopMin;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMin;

  static bool isDesktopXL(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopXLMin;
}

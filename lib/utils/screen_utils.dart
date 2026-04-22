import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class ScreenUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  static ScreenType getScreenType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width >= mobileBreakpoint && width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }
}

extension ScreenUtilsExtension on BuildContext {
  ScreenType get screenType => ScreenUtils.getScreenType(this);
  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;
}

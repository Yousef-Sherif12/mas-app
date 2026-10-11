import 'package:flutter/material.dart';
import 'package:masjid_app/core/constants/app_colors.dart';

enum AppThemeEnum {
  oldTheme,
  newLightTheme,
  newDarkTheme,
  theme4,
  hajTheme,
  hajTheme2,
  theme7,
}

extension AppThemeExtension on AppThemeEnum {
  String get videoPath {
    switch (this) {
      case AppThemeEnum.oldTheme:
        return "assets/videos/bg.mp4";
      case AppThemeEnum.newLightTheme:
        return "assets/videos/0524.mp4";
      case AppThemeEnum.newDarkTheme:
        return "assets/videos/bg1.mp4";
      case AppThemeEnum.theme4:
        return "assets/videos/bg3.mp4";
      case AppThemeEnum.hajTheme:
        return "assets/videos/haram3.mp4";
      case AppThemeEnum.hajTheme2:
        return "assets/videos/haram2.mp4";
      case AppThemeEnum.theme7:
        return "assets/videos/0922.mp4";
    }
  }

  Color get textColor {
    if (this == AppThemeEnum.hajTheme || this == AppThemeEnum.hajTheme2) {
      return hajTextColor;
    } else if (this == AppThemeEnum.newLightTheme) {
      return whiteBgTextColor;
    } else if (this == AppThemeEnum.theme7) {
      return theme7TextColor;
    }
    return defaultGoldTextColor;
  }

  Color get adhanTextColor {
    return this == AppThemeEnum.newLightTheme
        ? whiteBgTextColor
        : defaultGoldTextColor;
  }

  Color get gradientStartColor {
    if (this == AppThemeEnum.hajTheme || this == AppThemeEnum.hajTheme2) {
      return hajBackGroundColor1;
    } else if (this == AppThemeEnum.newLightTheme) {
      return whiteBgColor;
    }
    return defaultGradientStartColor;
  }

  Color get panelBackgroundColor {
    if (this == AppThemeEnum.newDarkTheme) {
      return Colors.black.withValues(alpha: 0.3);
    } else if (this == AppThemeEnum.newLightTheme) {
      return Colors.white.withValues(alpha: 0.06);
    }
    return Colors.transparent;
  }

  Color get blurOverlayColor {
    if (this == AppThemeEnum.theme4) {
      return Colors.black.withValues(alpha: 0.8);
    } else if (this == AppThemeEnum.hajTheme ||
        this == AppThemeEnum.hajTheme2) {
      return Colors.black.withValues(alpha: 0.65);
    } else if (this == AppThemeEnum.newLightTheme) {
      return Colors.black.withValues(alpha: 0.15);
    }
    return Colors.black.withValues(alpha: 0.3);
  }

  Color get lineColor {
    return this == AppThemeEnum.newLightTheme
        ? lightThemeLineColor
        : defaultLineGoldColor;
  }
}

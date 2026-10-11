import 'package:masjid_app/core/enums/app_theme_enum.dart';

class ThemeState {
  final AppThemeEnum currentTheme;
  final bool isVideoInitialized;
  final int version;

  const ThemeState({
    this.currentTheme = AppThemeEnum.newLightTheme,
    this.isVideoInitialized = false,
    this.version = 0,
  });

  ThemeState copyWith({
    AppThemeEnum? currentTheme,
    bool? isVideoInitialized,
    int? version,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      isVideoInitialized: isVideoInitialized ?? this.isVideoInitialized,
      version: version ?? this.version,
    );
  }
}

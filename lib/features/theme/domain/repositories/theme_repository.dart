import 'package:masjid_app/core/enums/app_theme_enum.dart';

abstract class ThemeRepository {
  Future<AppThemeEnum> loadTheme();
  Future<void> saveTheme(AppThemeEnum theme);
}

import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/features/theme/domain/repositories/theme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  static const String _themeKey = 'theme';

  @override
  Future<AppThemeEnum> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (saved == null) return AppThemeEnum.newLightTheme;

    return AppThemeEnum.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => AppThemeEnum.newLightTheme,
    );
  }

  @override
  Future<void> saveTheme(AppThemeEnum theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }
}

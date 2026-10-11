import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';

class Line extends StatelessWidget {
  const Line({
    super.key,
    this.height = 0.75,
    this.width = double.infinity,
    required this.currentTheme,
  });

  final double width;
  final double height;
  final AppThemeEnum currentTheme;

  @override
  Widget build(BuildContext context) {
    final color = currentTheme.lineColor;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color,
            color,
            Colors.transparent,
          ],
          stops: const [0.1, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }
}

class PrayerLine extends StatelessWidget {
  const PrayerLine({
    super.key,
    this.height = 1.5,
    this.width = double.infinity,
    required this.currentTheme,
  });

  final double width;
  final double height;
  final AppThemeEnum currentTheme;

  @override
  Widget build(BuildContext context) {
    final color = currentTheme.lineColor;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            color,
            color,
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 1.0],
        ),
      ),
    );
  }
}

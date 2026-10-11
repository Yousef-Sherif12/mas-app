import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';

class BlurOverlay extends StatelessWidget {
  const BlurOverlay({super.key, required this.currentTheme});

  final AppThemeEnum currentTheme;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: Container(
          color: currentTheme.blurOverlayColor,
        ),
      ),
    );
  }
}

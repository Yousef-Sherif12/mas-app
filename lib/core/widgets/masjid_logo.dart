import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, required this.currentTheme});

  final AppThemeEnum currentTheme;

  @override
  Widget build(BuildContext context) {
    final textColor = currentTheme.textColor;
    return Positioned(
      right: 15,
      top: 15,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              currentTheme.gradientStartColor,
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    'المسجـــــــــــــــــــد',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'الأهليّ الكويتيّ',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.mosque,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

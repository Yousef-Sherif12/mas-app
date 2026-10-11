import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_state_enum.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';

class NextPray extends StatelessWidget {
  const NextPray({
    super.key,
    required this.nextPray,
    required this.hours,
    required this.min,
    required this.sec,
    required this.appState,
    required this.iqamaCountdown,
    required this.currentTheme,
  });

  final String nextPray;
  final int hours, min, sec;
  final AppState appState;
  final String iqamaCountdown;
  final AppThemeEnum currentTheme;

  String formatDigitalTime(int h, int m, int s) {
    final formattedHours = h.toString().padLeft(2, '0');
    final formattedMinutes = m.toString().padLeft(2, '0');
    final formattedSeconds = s.toString().padLeft(2, '0');

    if (h > 0) {
      return '$formattedHours:$formattedMinutes:$formattedSeconds';
    } else {
      return '$formattedMinutes:$formattedSeconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIqamaMode = appState == AppState.iqamaCount;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            currentTheme.gradientStartColor,
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: isIqamaMode ? _buildIqamaView() : _buildNextPrayView(),
    );
  }

  Widget _buildIqamaView() {
    final textColor = currentTheme.textColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            iqamaCountdown,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 40,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Text(
            'الباقي على\nالإقامة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayView() {
    final textColor = currentTheme.textColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              formatDigitalTime(hours, min, sec),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 40,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            nextPray,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

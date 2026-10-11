import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/core/widgets/custom_line.dart';
import 'package:masjid_app/features/prayer/domain/entities/day_prayer.dart';

class PrayerTimes extends StatelessWidget {
  final AppThemeEnum currentTheme;
  final DayPrayer? prayerData;

  const PrayerTimes({
    super.key,
    required this.currentTheme,
    required this.prayerData,
  });

  static const Map<String, String> prayerIcons = {
    'الفجر': 'assets/icons/01-fajr.png',
    'الشروق': 'assets/icons/02-shorouq.png',
    'الظهر': 'assets/icons/03-duhur.png',
    'العصر': 'assets/icons/04-asr.png',
    'المغرب': 'assets/icons/05-mghreb.png',
    'العشاء': 'assets/icons/06-ishaa.png',
  };

  Widget _buildPrayerRow(String name, String time) {
    final List<String> parts = time.trim().split(' ');
    final String rawTimeNumbers = parts[0];
    final String rawPeriod = parts.length > 1 ? parts[1].toUpperCase() : "";
    final List<String> timeParts = rawTimeNumbers.split(':');
    final String hours = timeParts[0].padLeft(2, '0');
    final String minutes = timeParts[1].padLeft(2, '0');
    final String timeNumbers = "$hours:$minutes";
    final String arabicPeriod =
        (rawPeriod == "AM" || rawPeriod == "ص") ? "ص" : "م";
    final Color textColor = currentTheme.textColor;

    return Padding(
      padding: EdgeInsets.only(
        right: 10,
        left: arabicPeriod == 'م' ? 13 : 10,
        top: 3,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5.0, right: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              timeNumbers,
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                height: 0,
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                if (prayerIcons[name] != null)
                  Image.asset(
                    prayerIcons[name]!,
                    height: 20,
                    width: 20,
                    color: textColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (prayerData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final prayerNames = prayerData!.times.keys.toList();
    final prayerTimes = prayerData!.times.values.toList();

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(prayerNames.length, (index) {
          final bool isLastPrayer = index == prayerNames.length - 1;
          return Column(
            children: [
              _buildPrayerRow(prayerNames[index], prayerTimes[index]),
              !isLastPrayer
                  ? PrayerLine(currentTheme: currentTheme)
                  : const SizedBox(),
              SizedBox(height: !isLastPrayer ? 5 : 0),
            ],
          );
        }),
      ),
    );
  }
}

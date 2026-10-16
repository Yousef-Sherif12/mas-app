import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_state_enum.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/core/widgets/custom_line.dart';
import 'package:masjid_app/features/prayer/domain/entities/day_prayer.dart';
import 'package:masjid_app/features/prayer/presentation/widgets/next_pray_widget.dart';
import 'package:masjid_app/features/prayer/presentation/widgets/prayer_times_list.dart';

class PrayerTimesAndDateColunm extends StatelessWidget {
  const PrayerTimesAndDateColunm({
    super.key,
    required this.hijriDate,
    required this.date,
    required this.day,
    required this.fullTime,
    required this.nextPrayName,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.iqamaTime,
    required this.appState,
    required this.currentTheme,
    required this.prayerData,
    this.dateFontSize = 15.0,
  });

  final String hijriDate;
  final String date;
  final String day;
  final String fullTime;
  final String nextPrayName;
  final int hours, minutes, seconds;
  final String iqamaTime;
  final AppState appState;
  final AppThemeEnum currentTheme;
  final DayPrayer? prayerData;
  final double dateFontSize;

  @override
  Widget build(BuildContext context) {
    final textColor = currentTheme.textColor;
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.only(right: 0, top: 10, bottom: 42, left: 0),
        padding: const EdgeInsets.only(left: 5, right: 5),
        decoration: BoxDecoration(
          color: currentTheme.panelBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Line(height: 1, currentTheme: currentTheme),
            const SizedBox(height: 2),
            TimeAndDate(
              hijriDate: hijriDate,
              date: date,
              day: day,
              fullTime: fullTime,
              currentTheme: currentTheme,
              dateFontSize: dateFontSize,
            ),
            const SizedBox(height: 4),
            Text(
              'مواقيت الصلاة',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                fontSize: 25,
                height: 1,
              ),
            ),
            Line(height: 0.7, currentTheme: currentTheme),
            const SizedBox(height: 0),
            PrayerTimes(
              prayerData: prayerData,
              currentTheme: currentTheme,
            ),
            const SizedBox(height: 3),
            NextPray(
              nextPray: nextPrayName,
              hours: hours,
              min: minutes,
              sec: seconds,
              appState: appState,
              iqamaCountdown: iqamaTime,
              currentTheme: currentTheme,
            ),
            Line(height: 1, currentTheme: currentTheme),
          ],
        ),
      ),
    );
  }
}

class TimeAndDate extends StatelessWidget {
  const TimeAndDate({
    super.key,
    required this.hijriDate,
    required this.date,
    required this.day,
    required this.fullTime,
    required this.currentTheme,
    this.dateFontSize = 15.0,
  });

  final String hijriDate;
  final String date;
  final String day;
  final String fullTime;
  final AppThemeEnum currentTheme;
  final double dateFontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, left: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Date(
            hijriDate: hijriDate,
            date: date,
            day: day,
            currentTheme: currentTheme,
            dateFontSize: dateFontSize,
          ),
          const SizedBox(width: 4),
          DayAndTime(fullTime: fullTime, currentTheme: currentTheme),
        ],
      ),
    );
  }
}

class Date extends StatelessWidget {
  const Date({
    super.key,
    required this.hijriDate,
    required this.date,
    required this.day,
    required this.currentTheme,
    this.dateFontSize = 15.0,
  });

  final String hijriDate;
  final String date;
  final String day;
  final AppThemeEnum currentTheme;
  final double dateFontSize;

  @override
  Widget build(BuildContext context) {
    final textColor = currentTheme.textColor;
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              day,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: dateFontSize + 1,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hijriDate,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: dateFontSize,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$dateم',
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: dateFontSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DayAndTime extends StatelessWidget {
  const DayAndTime({
    super.key,
    required this.fullTime,
    required this.currentTheme,
  });

  final String fullTime;
  final AppThemeEnum currentTheme;

  @override
  Widget build(BuildContext context) {
    final timeParts = fullTime.split(' ');
    final timeOnly = timeParts[0];

    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            height: 70,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeOnly,
                    style: TextStyle(
                      color: currentTheme.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 60,
                      fontFamily: 'Tajawal',
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

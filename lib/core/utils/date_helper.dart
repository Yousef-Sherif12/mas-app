import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;

class DateHelper {
  static int hijriOffset = 0; // -1 أو +1 حسب الرؤية

  static String formatDate(DateTime now) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return "${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}";
  }

  static String formatTime(DateTime now) {
    int hour = now.hour;
    int minute = now.minute;
    bool isPM = hour >= 12;

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    String period = isPM ? 'م' : 'ص';

    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
  }

  static String formatDay(DateTime now) {
    return intl.DateFormat('EEEE', 'ar').format(now);
  }

  static String formatHijriDate(DateTime now) {
    const hijriMonths = [
      "محرم",
      "صفر",
      "ربيع الأول",
      "ربيع الآخر",
      "جمادى الأولى",
      "جمادى الآخرة",
      "رجب",
      "شعبان",
      "رمضان",
      "شوال",
      "ذو القعدة",
      "ذو الحجة",
    ];

    final adjustedDate = now.add(Duration(days: hijriOffset));
    final hijri = HijriCalendar.fromDate(adjustedDate);

    return "${hijri.hDay} ${hijriMonths[hijri.hMonth - 1]} ${hijri.hYear}هـ";
  }
}

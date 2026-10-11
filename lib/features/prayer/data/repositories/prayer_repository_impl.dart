import 'package:masjid_app/features/prayer/data/datasources/prayer_data_source.dart';
import 'package:masjid_app/features/prayer/domain/entities/day_prayer.dart';
import 'package:masjid_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerDataSource _dataSource;

  PrayerRepositoryImpl(this._dataSource);

  @override
  Future<DayPrayer?> getTodayPrayers() => _dataSource.getTodayPrayers();

  @override
  Future<Map<String, int>> getIqamaTimes() => _dataSource.getIqamaTimes();

  @override
  Stream<Map<String, int>> listenToIqamaTimes() =>
      _dataSource.listenToIqamaTimes();

  @override
  Future<({String? prayerName, DateTime? triggeredAt})>
      loadSavedAdhanState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrayer = prefs.getString('last_adhan_prayer');
    final savedTimeStr = prefs.getString('adhan_triggered_at');

    if (savedPrayer == null || savedTimeStr == null) {
      return (prayerName: null, triggeredAt: null);
    }

    final adhanTime = DateTime.tryParse(savedTimeStr);
    return (prayerName: savedPrayer, triggeredAt: adhanTime);
  }

  @override
  Future<void> saveAdhanState(String prayerName, DateTime triggeredAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_adhan_prayer', prayerName);
    await prefs.setString('adhan_triggered_at', triggeredAt.toIso8601String());
  }

  @override
  Future<void> clearAdhanState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_adhan_prayer');
    await prefs.remove('adhan_triggered_at');
  }

  @override
  DateTime parseTime(String timeStr, DateTime date) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPM = clean.contains("PM");
      final timePart = clean.replaceAll("AM", "").replaceAll("PM", "").trim();
      final parts = timePart.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return date;
    }
  }

  @override
  Map<String, dynamic> calculateCountdown(DayPrayer? todayPrayerData) {
    if (todayPrayerData == null) {
      return {"name": "-", "h": 0, "m": 0, "s": 0};
    }

    final now = DateTime.now();
    const prayerOrder = [
      "الفجر",
      "الشروق",
      "الظهر",
      "العصر",
      "المغرب",
      "العشاء",
    ];

    for (final prayerName in prayerOrder) {
      final timeStr = todayPrayerData.times[prayerName];
      if (timeStr == null) continue;
      final prayerTime = parseTime(timeStr, now);

      final diffSeconds = prayerTime.difference(now).inSeconds;
      if (diffSeconds > 0) {
        final diff = Duration(seconds: diffSeconds);
        return {
          "name": prayerName,
          "h": diff.inHours,
          "m": diff.inMinutes % 60,
          "s": diff.inSeconds % 60,
        };
      }
    }

    final fajrStr = todayPrayerData.times["الفجر"] ?? "4:00 AM";
    final tomorrow = now.add(const Duration(days: 1));
    final nextFajr = parseTime(fajrStr, tomorrow);
    final diff = nextFajr.difference(now);
    return {
      "name": "الفجر",
      "h": diff.inHours,
      "m": diff.inMinutes % 60,
      "s": diff.inSeconds % 60,
    };
  }

  @override
  String getCurrentPrayerName(DayPrayer? todayPrayerData) {
    if (todayPrayerData == null) return "";

    final now = DateTime.now();
    // استبعاد الشروق من تحديد الصلاة المفروضة الحالية حتى لا تصبح مدة الإقامة 5 دقائق بالخطأ
    const prayerOrder = [
      "العشاء",
      "المغرب",
      "العصر",
      "الظهر",
      "الفجر",
    ];

    for (final prayerName in prayerOrder) {
      final timeStr = todayPrayerData.times[prayerName];
      if (timeStr == null) continue;
      final prayerTime = parseTime(timeStr, now);

      // السماح بهامش 15 دقيقة قبل وقت الصلاة لو ضغط الإمام الزر الأحمر مبكراً قليلاً
      if (now.isAfter(prayerTime.subtract(const Duration(minutes: 15)))) {
        return prayerName;
      }
    }
    return "العشاء";
  }
}

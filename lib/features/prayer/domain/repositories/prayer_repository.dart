import 'package:masjid_app/features/prayer/domain/entities/day_prayer.dart';

abstract class PrayerRepository {
  Future<DayPrayer?> getTodayPrayers();
  Future<Map<String, int>> getIqamaTimes();
  Stream<Map<String, int>> listenToIqamaTimes();
  Future<int> getHijriOffset();
  Stream<int> listenToHijriOffset();
  Future<({String? prayerName, DateTime? triggeredAt})> loadSavedAdhanState();
  Future<void> saveAdhanState(String prayerName, DateTime triggeredAt);
  Future<void> clearAdhanState();
  DateTime parseTime(String timeStr, DateTime date);
  Map<String, dynamic> calculateCountdown(DayPrayer? todayPrayerData);
  String getCurrentPrayerName(DayPrayer? todayPrayerData);
}

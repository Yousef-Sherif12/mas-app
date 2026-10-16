import 'package:masjid_app/core/enums/app_state_enum.dart';
import 'package:masjid_app/features/prayer/domain/entities/day_prayer.dart';

class PrayerState {
  final DayPrayer? todayPrayerData;
  final Map<String, int> iqamaTimes;
  final AppState appState;
  final String currentPrayerName;
  final String iqamaCountdown;
  final DateTime now;
  final Map<String, dynamic> countdown;
  final bool isManualAdhkar;
  final bool isManualIqama;
  final int hijriOffset;
  final double dateFontSize;

  const PrayerState({
    this.todayPrayerData,
    this.iqamaTimes = const {},
    this.appState = AppState.normal,
    this.currentPrayerName = '',
    this.iqamaCountdown = '',
    required this.now,
    this.countdown = const {"name": "-", "h": 0, "m": 0, "s": 0},
    this.isManualAdhkar = false,
    this.isManualIqama = false,
    this.hijriOffset = 0,
    this.dateFontSize = 15.0,
  });

  PrayerState copyWith({
    DayPrayer? todayPrayerData,
    Map<String, int>? iqamaTimes,
    AppState? appState,
    String? currentPrayerName,
    String? iqamaCountdown,
    DateTime? now,
    Map<String, dynamic>? countdown,
    bool? isManualAdhkar,
    bool? isManualIqama,
    int? hijriOffset,
    double? dateFontSize,
  }) {
    return PrayerState(
      todayPrayerData: todayPrayerData ?? this.todayPrayerData,
      iqamaTimes: iqamaTimes ?? this.iqamaTimes,
      appState: appState ?? this.appState,
      currentPrayerName: currentPrayerName ?? this.currentPrayerName,
      iqamaCountdown: iqamaCountdown ?? this.iqamaCountdown,
      now: now ?? this.now,
      countdown: countdown ?? this.countdown,
      isManualAdhkar: isManualAdhkar ?? this.isManualAdhkar,
      isManualIqama: isManualIqama ?? this.isManualIqama,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      dateFontSize: dateFontSize ?? this.dateFontSize,
    );
  }
}

import 'package:masjid_app/features/prayer/domain/entities/day_prayer.dart';

class DayPrayerModel extends DayPrayer {
  const DayPrayerModel({
    required super.date,
    required super.times,
  });

  factory DayPrayerModel.fromJson(Map<String, dynamic> json) {
    return DayPrayerModel(
      date: json['date']?.toString() ?? '',
      times: Map<String, String>.from(json['times'] as Map),
    );
  }
}

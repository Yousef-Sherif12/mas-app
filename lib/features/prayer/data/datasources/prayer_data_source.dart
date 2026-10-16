import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masjid_app/features/prayer/data/models/day_prayer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerDataSource {
  final FirebaseFirestore _db;

  PrayerDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<DayPrayerModel?> getTodayPrayers() async {
    final String response = await rootBundle.loadString(
      'assets/jsons/prayer_times_.json',
    );
    final List<dynamic> data = json.decode(response);

    final String todayDate = intl.DateFormat(
      'yyyy-MM-dd',
      'en',
    ).format(DateTime.now());

    try {
      final todayData = data.firstWhere(
        (element) => element['date'] == todayDate,
      );
      return DayPrayerModel.fromJson(
        Map<String, dynamic>.from(todayData as Map),
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> _hasNewIqamaVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getInt('iqama_version') ?? 0;

      final doc = await _db
          .collection('settings')
          .doc('versions')
          .get()
          .timeout(const Duration(seconds: 5));

      final remoteVersion =
          (doc.data()?['iqama_version'] ?? doc.data()?['messages_version'] ?? 0)
              as int;

      if (remoteVersion > localVersion) {
        await prefs.setInt('iqama_version', remoteVersion);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, int>> getIqamaTimes() async {
    const cacheKey = 'cache_iqama_times';
    final hasUpdate = await _hasNewIqamaVersion();
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);

    if (hasUpdate || cached == null) {
      try {
        final doc = await _db
            .collection('settings')
            .doc('iqama_times')
            .get()
            .timeout(const Duration(seconds: 5));

        final data = Map<String, dynamic>.from(doc.data() ?? {});
        if (data.isNotEmpty) {
          await prefs.setString(cacheKey, jsonEncode(data));
          return data.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      } catch (e) {
        if (cached != null) {
          final data = Map<String, dynamic>.from(jsonDecode(cached) as Map);
          return data.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      }

      final ByteData byteData = await rootBundle.load(
        'assets/jsons/iqama_times.json',
      );
      final String response = utf8.decode(byteData.buffer.asUint8List());
      final Map<String, dynamic> jsonData =
          Map<String, dynamic>.from(json.decode(response) as Map);
      return jsonData.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    final data = Map<String, dynamic>.from(jsonDecode(cached) as Map);
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Stream<Map<String, int>> listenToIqamaTimes() {
    return _db
        .collection('settings')
        .doc('iqama_times')
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null || data.isEmpty) return <String, int>{};

      final parsed = data.map((k, v) => MapEntry(k, (v as num).toInt()));
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_iqama_times', jsonEncode(parsed));
        // ignore: empty_catches
      } catch (e) {}
      return parsed;
    });
  }

  Future<int> getHijriOffset() async {
    const cacheKey = 'cache_hijri_offset';
    final prefs = await SharedPreferences.getInstance();
    try {
      final doc = await _db
          .collection('settings')
          .doc('display_settings')
          .get()
          .timeout(const Duration(seconds: 5));
      final offset = (doc.data()?['hijri_offset'] as num?)?.toInt();
      if (offset != null) {
        await prefs.setInt(cacheKey, offset);
        return offset;
      }
    } catch (_) {}
    return prefs.getInt(cacheKey) ?? 0;
  }

  Stream<int> listenToHijriOffset() {
    return _db
        .collection('settings')
        .doc('display_settings')
        .snapshots()
        .asyncMap((snapshot) async {
      final offset = (snapshot.data()?['hijri_offset'] as num?)?.toInt() ?? 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cache_hijri_offset', offset);
      } catch (_) {}
      return offset;
    });
  }

  Stream<double> listenToDateFontSize() {
    return _db
        .collection('settings')
        .doc('display_settings')
        .snapshots()
        .map((snapshot) {
      final size = snapshot.data()?['date_font_size'];
      if (size is num) return size.toDouble();
      return 15.0;
    });
  }
}

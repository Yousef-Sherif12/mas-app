import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:masjid_app/features/content/data/models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContentDataSource {
  final FirebaseFirestore _db;

  bool _versionCheckedThisSession = false;
  bool _hasUpdateThisSession = false;

  ContentDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  void resetSessionCache() {
    _versionCheckedThisSession = false;
    _hasUpdateThisSession = false;
  }

  Future<void> _saveToCache(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<List<Map<String, dynamic>>?> _loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached == null) return null;
      final List<dynamic> raw = jsonDecode(cached) as List<dynamic>;
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<bool> _hasNewVersion(String versionKey) async {
    if (_versionCheckedThisSession) return _hasUpdateThisSession;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getInt(versionKey) ?? 0;

      final doc = await _db
          .collection('settings')
          .doc('versions')
          .get()
          .timeout(const Duration(seconds: 5));

      final remoteVersion = (doc.data()?['messages_version'] ?? 0) as int;

      _versionCheckedThisSession = true;

      if (remoteVersion > localVersion) {
        // Do not update prefs here so the listener detects remoteVersion > localVersion and clears cache
        _hasUpdateThisSession = true;
        return true;
      }

      _hasUpdateThisSession = false;
      return false;
    } catch (e) {
      _versionCheckedThisSession = true;
      _hasUpdateThisSession = false;
      return false;
    }
  }

  List<MessageModel> _parseMessages(
    List<Map<String, dynamic>> data, {
    String? defaultType,
  }) {
    return data
        .map((e) {
          try {
            final item = Map<String, dynamic>.from(e);
            if ((item['type'] == null ||
                    item['type'].toString().trim().isEmpty) &&
                defaultType != null) {
              item['type'] = defaultType;
            }
            return MessageModel.fromMap(item);
          } catch (_) {
            return const MessageModel(type: '', text: '');
          }
        })
        .where((m) => m.text.isNotEmpty)
        .toList();
  }

  String _getLocalPath(String collection) {
    const paths = {
      'quran_messages': 'assets/jsons/quran_messages.json',
      'hadith': 'assets/jsons/hadith_messages.json',
      'hadith_messages': 'assets/jsons/hadith_messages.json',
      'prayer_from_quran': 'assets/jsons/prayer_from_quran.json',
      'thaqil': 'assets/jsons/thaqil.json',
      'adhkar_salah': 'assets/jsons/adhkar_salah.json',
      'adhkar_sabah': 'assets/jsons/sabah_adhkar.json',
      'adhkar_masa': 'assets/jsons/masaa_adhkar.json',
    };
    return paths[collection] ?? '';
  }

  Future<List<MessageModel>> _loadFromLocalJson(
    String path, {
    String? defaultType,
  }) async {
    if (path.isEmpty) return [];
    try {
      final ByteData data = await rootBundle.load(path);
      final String response = utf8.decode(data.buffer.asUint8List());
      final List<dynamic> jsonData = json.decode(response) as List<dynamic>;
      return _parseMessages(
        jsonData.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        defaultType: defaultType,
      );
    } catch (e) {
      return [];
    }
  }

  String _inferDefaultType(String collection) {
    final lower = collection.toLowerCase();
    if (lower.contains('quran')) return 'quran';
    if (lower.contains('hadith')) return 'hadith';
    if (lower.contains('prayer')) return 'prayer_from_quran';
    if (lower.contains('thaqil')) return 'thaqil';
    return lower;
  }

  Future<List<MessageModel>> getMessages(String collection) async {
    final cacheKey = 'cache_$collection';
    const versionKey = 'messages_version';
    final defaultType = _inferDefaultType(collection);

    final hasUpdate = await _hasNewVersion(versionKey);
    final cached = await _loadFromCache(cacheKey);

    if (hasUpdate || cached == null) {
      try {
        final snapshot = await _db
            .collection(collection)
            .orderBy('order')
            .get()
            .timeout(const Duration(seconds: 10));

        final data = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        await _saveToCache(cacheKey, data);
        return _parseMessages(data, defaultType: defaultType);
      } catch (e) {
        if (cached != null && cached.isNotEmpty) {
          return _parseMessages(cached, defaultType: defaultType);
        }
        return _loadFromLocalJson(
          _getLocalPath(collection),
          defaultType: defaultType,
        );
      }
    }

    return _parseMessages(cached, defaultType: defaultType);
  }

  Future<List<Map<String, dynamic>>> getActiveCollections() async {
    const cacheKey = 'cache_active_collections';

    try {
      final snapshot = await _db
          .collection('collections_config')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .get()
          .timeout(const Duration(seconds: 5));

      final data = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': (doc.data()['id'] ?? doc.id).toString(),
              })
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(data));

      return data;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(
          (jsonDecode(cached) as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [
        {'id': 'quran_messages', 'label': 'قال الله تعالى', 'order': 0},
        {'id': 'hadith', 'label': 'قال النبي ﷺ', 'order': 1},
        {'id': 'thaqil', 'label': 'ثَقِّلْ مَوَازِينَكَ', 'order': 2},
        {'id': 'prayer_from_quran', 'label': 'أدعية من القرآن والسنة', 'order': 3},
      ];
    }
  }

  Stream<int> listenToMessagesVersion() {
    return _db
        .collection('settings')
        .doc('versions')
        .snapshots()
        .map((snapshot) => (snapshot.data()?['messages_version'] ?? 0) as int);
  }

  Stream<List<Map<String, dynamic>>> listenToCollectionsConfig() {
    return _db.collection('collections_config').snapshots().map((snapshot) {
      final activeDocs = snapshot.docs
          .where((doc) => doc.data()['active'] == true)
          .map((doc) => {
                ...doc.data(),
                'id': (doc.data()['id'] ?? doc.id).toString(),
              })
          .toList()
        ..sort((a, b) => ((a['order'] ?? 0) as num)
            .compareTo((b['order'] ?? 0) as num));
      return activeDocs;
    });
  }

  Stream<Map<String, dynamic>?> listenToLiveDisplay() {
    return _db
        .collection('settings')
        .doc('live_display')
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Stream<String> listenToContentFontFamily() {
    return _db
        .collection('settings')
        .doc('display_settings')
        .snapshots()
        .map((snapshot) {
      final font = snapshot.data()?['content_font_family']?.toString() ?? 'Roboto';
      return (font == 'Tajawal' || font == 'Roboto') ? font : 'Roboto';
    });
  }
}

import 'package:masjid_app/features/content/data/datasources/content_data_source.dart';
import 'package:masjid_app/features/content/domain/entities/message.dart';
import 'package:masjid_app/features/content/domain/repositories/content_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentDataSource _dataSource;

  ContentRepositoryImpl(this._dataSource);

  @override
  Future<List<Map<String, dynamic>>> getActiveCollections() =>
      _dataSource.getActiveCollections();

  @override
  Future<List<Message>> getCollectionMessages(String collection) =>
      _dataSource.getMessages(collection);

  @override
  Future<List<Message>> getAdhkarSalah() =>
      _dataSource.getMessages('adhkar_salah');

  @override
  Future<List<Message>> getAdhkarSabah() =>
      _dataSource.getMessages('adhkar_sabah');

  @override
  Future<List<Message>> getAdhkarMasa() =>
      _dataSource.getMessages('adhkar_masa');

  @override
  Stream<int> listenToMessagesVersion() =>
      _dataSource.listenToMessagesVersion();

  @override
  Stream<List<Map<String, dynamic>>> listenToCollectionsConfig() =>
      _dataSource.listenToCollectionsConfig();

  @override
  Stream<Map<String, dynamic>?> listenToLiveDisplay() =>
      _dataSource.listenToLiveDisplay();

  @override
  Stream<String> listenToContentFontFamily() =>
      _dataSource.listenToContentFontFamily();

  @override
  Future<int> getLocalMessagesVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('messages_version') ?? 0;
  }

  @override
  Future<void> setLocalMessagesVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('messages_version', version);
  }

  @override
  Future<void> clearAllMessageCaches() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKeys =
        prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final k in cacheKeys) {
      await prefs.remove(k);
    }
  }

  @override
  Future<void> clearActiveCollectionsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_active_collections');
  }

  @override
  void resetSessionCache() => _dataSource.resetSessionCache();
}

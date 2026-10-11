import 'package:masjid_app/features/content/domain/entities/message.dart';

abstract class ContentRepository {
  Future<List<Map<String, dynamic>>> getActiveCollections();
  Future<List<Message>> getCollectionMessages(String collection);
  Future<List<Message>> getAdhkarSalah();
  Future<List<Message>> getAdhkarSabah();
  Future<List<Message>> getAdhkarMasa();
  Stream<int> listenToMessagesVersion();
  Stream<List<Map<String, dynamic>>> listenToCollectionsConfig();
  Stream<Map<String, dynamic>?> listenToLiveDisplay();
  Future<int> getLocalMessagesVersion();
  Future<void> setLocalMessagesVersion(int version);
  Future<void> clearAllMessageCaches();
  Future<void> clearActiveCollectionsCache();
  void resetSessionCache();
}

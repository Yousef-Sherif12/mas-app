import 'package:masjid_app/core/enums/adhkar_type_enum.dart';
import 'package:masjid_app/features/content/domain/entities/message.dart';

class ContentState {
  final List<Map<String, dynamic>> activeCollections;
  final List<String> activeCollectionKeys;
  final Map<String, List<Message>> collectionMessages;
  final Map<String, int> collectionIndices;
  final int contentTypeIndex;

  final List<Message> adhkarSalahMessages;
  final List<Message> adhkarSabahMessages;
  final List<Message> adhkarMasaMessages;
  final List<Message> adhkarMessages;
  final int adhkarIndex;
  final AdhkarType currentAdhkarType;

  final Message? liveMessage;
  final bool isLiveDisplay;

  const ContentState({
    this.activeCollections = const [],
    this.activeCollectionKeys = const [],
    this.collectionMessages = const {},
    this.collectionIndices = const {},
    this.contentTypeIndex = 0,
    this.adhkarSalahMessages = const [],
    this.adhkarSabahMessages = const [],
    this.adhkarMasaMessages = const [],
    this.adhkarMessages = const [],
    this.adhkarIndex = 0,
    this.currentAdhkarType = AdhkarType.salah,
    this.liveMessage,
    this.isLiveDisplay = false,
  });

  Message? get currentMainMessage {
    if (activeCollectionKeys.isEmpty) return null;
    final key =
        activeCollectionKeys[contentTypeIndex % activeCollectionKeys.length];
    final messages = collectionMessages[key] ?? [];
    if (messages.isEmpty) return null;
    final index = collectionIndices[key] ?? 0;
    return messages[index % messages.length];
  }

  Message? get displayMessage =>
      isLiveDisplay ? liveMessage : currentMainMessage;

  String get currentCollectionLabel {
    if (activeCollectionKeys.isEmpty) return '';
    final key =
        activeCollectionKeys[contentTypeIndex % activeCollectionKeys.length];
    final col = activeCollections.firstWhere(
      (c) => c['id'] == key,
      orElse: () => {'label': ''},
    );
    return col['label']?.toString() ?? '';
  }

  ContentState copyWith({
    List<Map<String, dynamic>>? activeCollections,
    List<String>? activeCollectionKeys,
    Map<String, List<Message>>? collectionMessages,
    Map<String, int>? collectionIndices,
    int? contentTypeIndex,
    List<Message>? adhkarSalahMessages,
    List<Message>? adhkarSabahMessages,
    List<Message>? adhkarMasaMessages,
    List<Message>? adhkarMessages,
    int? adhkarIndex,
    AdhkarType? currentAdhkarType,
    Message? liveMessage,
    bool clearLiveMessage = false,
    bool? isLiveDisplay,
  }) {
    return ContentState(
      activeCollections: activeCollections ?? this.activeCollections,
      activeCollectionKeys: activeCollectionKeys ?? this.activeCollectionKeys,
      collectionMessages: collectionMessages ?? this.collectionMessages,
      collectionIndices: collectionIndices ?? this.collectionIndices,
      contentTypeIndex: contentTypeIndex ?? this.contentTypeIndex,
      adhkarSalahMessages: adhkarSalahMessages ?? this.adhkarSalahMessages,
      adhkarSabahMessages: adhkarSabahMessages ?? this.adhkarSabahMessages,
      adhkarMasaMessages: adhkarMasaMessages ?? this.adhkarMasaMessages,
      adhkarMessages: adhkarMessages ?? this.adhkarMessages,
      adhkarIndex: adhkarIndex ?? this.adhkarIndex,
      currentAdhkarType: currentAdhkarType ?? this.currentAdhkarType,
      liveMessage: clearLiveMessage ? null : (liveMessage ?? this.liveMessage),
      isLiveDisplay: isLiveDisplay ?? this.isLiveDisplay,
    );
  }
}

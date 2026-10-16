import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masjid_app/core/enums/adhkar_type_enum.dart';
import 'package:masjid_app/features/content/domain/entities/message.dart';
import 'package:masjid_app/features/content/domain/repositories/content_repository.dart';
import 'package:masjid_app/features/content/presentation/cubit/content_state.dart';

class ContentCubit extends Cubit<ContentState> {
  final ContentRepository _repository;
  final void Function()? onAdhkarCompleted;

  Timer? _rotationTimer;
  Timer? _adhkarTimer;
  Timer? _watchdogTimer;

  StreamSubscription<int>? _versionSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _collectionsSubscription;
  StreamSubscription<Map<String, dynamic>?>? _liveDisplaySubscription;
  StreamSubscription<String>? _displaySettingsSubscription;

  ContentCubit(
    this._repository, {
    this.onAdhkarCompleted,
  }) : super(const ContentState());

  Future<void> init() async {
    await _loadAllMessages();
    _listenToVersionChanges();
    _listenToCollectionsChanges();
    _listenToLiveDisplay();
    _listenToDisplaySettings();
    _startWatchdogTimer();
  }

  void _startWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isClosed || state.isLiveDisplay) return;
      if (_rotationTimer == null || !_rotationTimer!.isActive) {
        startRotationTimer();
      }
    });
  }

  void _listenToDisplaySettings() {
    _displaySettingsSubscription?.cancel();
    _displaySettingsSubscription =
        _repository.listenToContentFontFamily().listen((font) {
      if (isClosed) return;
      if (font != state.contentFontFamily) {
        emit(state.copyWith(contentFontFamily: font));
      }
    });
  }

  Future<void> _loadAllMessages() async {
    final activeCollections = await _repository.getActiveCollections();
    final keys = activeCollections
        .map((c) => (c['id'] ?? '').toString())
        .where((k) => k.isNotEmpty)
        .toList();

    final Map<String, List<Message>> messages = {};
    for (final key in keys) {
      messages[key] = await _repository.getCollectionMessages(key);
    }

    final salah = await _repository.getAdhkarSalah();
    final sabah = await _repository.getAdhkarSabah();
    final masa = await _repository.getAdhkarMasa();

    if (isClosed) return;

    final newIndices = {for (final k in keys) k: 0};

    emit(
      state.copyWith(
        activeCollections: activeCollections,
        activeCollectionKeys: keys,
        collectionMessages: messages,
        collectionIndices: newIndices,
        contentTypeIndex: 0,
        adhkarSalahMessages: salah,
        adhkarSabahMessages: sabah,
        adhkarMasaMessages: masa,
      ),
    );

    startRotationTimer();
  }

  void _listenToVersionChanges() {
    _versionSubscription?.cancel();
    _versionSubscription =
        _repository.listenToMessagesVersion().listen((remoteVersion) async {
      if (isClosed) return;
      final localVersion = await _repository.getLocalMessagesVersion();
      if (remoteVersion > localVersion) {
        await _repository.clearAllMessageCaches();
        await _repository.setLocalMessagesVersion(remoteVersion);
        _repository.resetSessionCache();
        await _loadAllMessages();
      }
    });
  }

  void _listenToCollectionsChanges() {
    _collectionsSubscription?.cancel();
    _collectionsSubscription =
        _repository.listenToCollectionsConfig().listen((newActiveDocs) async {
      if (isClosed) return;
      final keys = newActiveDocs
          .map((doc) => (doc['id'] ?? '').toString())
          .where((k) => k.isNotEmpty)
          .toList();

      if (keys.toString() != state.activeCollectionKeys.toString()) {
        await _repository.clearActiveCollectionsCache();

        final Map<String, List<Message>> messages = {};
        for (final key in keys) {
          messages[key] = state.collectionMessages[key] ??
              await _repository.getCollectionMessages(key);
        }

        if (isClosed) return;

        final newIndices = {for (final k in keys) k: 0};

        emit(
          state.copyWith(
            activeCollections: newActiveDocs,
            activeCollectionKeys: keys,
            collectionMessages: messages,
            collectionIndices: newIndices,
            contentTypeIndex: 0,
          ),
        );

        startRotationTimer();
      } else if (jsonEncode(newActiveDocs) !=
          jsonEncode(state.activeCollections)) {
        // تحديث العناوين (labels) فوراً لو تغيرت دون تغير الـ IDs
        emit(state.copyWith(activeCollections: newActiveDocs));
      }
    });
  }

  void _listenToLiveDisplay() {
    _liveDisplaySubscription?.cancel();
    _liveDisplaySubscription =
        _repository.listenToLiveDisplay().listen((data) {
      if (isClosed) return;

      if (data == null || data['active'] != true) {
        if (state.isLiveDisplay) {
          emit(
            state.copyWith(
              isLiveDisplay: false,
              clearLiveMessage: true,
            ),
          );
          startRotationTimer();
        }
        return;
      }

      final collection = data['collection']?.toString() ?? '';
      final docId = data['docId']?.toString() ?? '';
      if (collection.isEmpty || docId.isEmpty) return;

      final allMessages = <String, List<Message>>{
        ...state.collectionMessages,
        'adhkar_salah': state.adhkarSalahMessages,
        'adhkar_sabah': state.adhkarSabahMessages,
        'adhkar_masa': state.adhkarMasaMessages,
      };

      Message? found;
      final list = allMessages[collection];
      if (list != null) {
        try {
          found = list.firstWhere((msg) => msg.docId == docId);
        } catch (_) {
          found = null;
        }
      }

      if (found != null) {
        _rotationTimer?.cancel();
        emit(
          state.copyWith(
            liveMessage: found,
            isLiveDisplay: true,
          ),
        );
      }
    });
  }

  void _advanceContentState() {
    if (state.activeCollectionKeys.isEmpty) return;
    final key = state.activeCollectionKeys[
        state.contentTypeIndex % state.activeCollectionKeys.length];
    final messages = state.collectionMessages[key] ?? [];
    final updatedIndices = Map<String, int>.from(state.collectionIndices);

    if (messages.isNotEmpty) {
      final currentIndex = updatedIndices[key] ?? 0;
      updatedIndices[key] = (currentIndex + 1) % messages.length;
    }

    final nextTypeIndex =
        (state.contentTypeIndex + 1) % state.activeCollectionKeys.length;

    emit(
      state.copyWith(
        collectionIndices: updatedIndices,
        contentTypeIndex: nextTypeIndex,
      ),
    );
  }

  void startRotationTimer() {
    _rotationTimer?.cancel();
    if (state.isLiveDisplay) return;
    if (state.activeCollectionKeys.isEmpty) return;

    final hasAnyMessage = state.activeCollectionKeys
        .any((k) => (state.collectionMessages[k] ?? []).isNotEmpty);
    if (!hasAnyMessage) return;

    Message? current = state.currentMainMessage;
    int attempts = 0;
    while (current == null && attempts < state.activeCollectionKeys.length) {
      _advanceContentState();
      current = state.currentMainMessage;
      attempts++;
    }

    if (current == null) return;

    _rotationTimer = Timer(current.duration, () {
      if (isClosed) return;
      _advanceContentState();
      startRotationTimer();
    });
  }

  List<Message> _getAdhkarByType(AdhkarType type) {
    switch (type) {
      case AdhkarType.sabah:
        return [...state.adhkarSabahMessages];
      case AdhkarType.masa:
        return [...state.adhkarMasaMessages];
      case AdhkarType.salah:
        return [...state.adhkarSalahMessages];
    }
  }

  List<Message> _getAdhkarForPrayer(String prayerName) {
    if (prayerName == "الفجر") {
      return [
        ...state.adhkarSalahMessages,
        ...state.adhkarSabahMessages,
        ...state.adhkarSabahMessages, // عرض أذكار الصباح مرتين بعد الفجر كما هو مطلوب
      ];
    } else if (prayerName == "العصر") {
      return [
        ...state.adhkarSalahMessages,
        ...state.adhkarMasaMessages,
      ];
    } else {
      return [...state.adhkarSalahMessages];
    }
  }

  void startPrayerAdhkar(String prayerName) {
    _rotationTimer?.cancel();
    _adhkarTimer?.cancel();
    final adhkarList = _getAdhkarForPrayer(prayerName);
    emit(
      state.copyWith(
        adhkarIndex: 0,
        adhkarMessages: adhkarList,
      ),
    );
    _runNextZikr();
  }

  void startManualAdhkar(AdhkarType type) {
    _rotationTimer?.cancel();
    _adhkarTimer?.cancel();
    final adhkarList = _getAdhkarByType(type);
    emit(
      state.copyWith(
        adhkarIndex: 0,
        currentAdhkarType: type,
        adhkarMessages: adhkarList,
      ),
    );
    _runNextZikr();
  }

  void stopAdhkar() {
    _adhkarTimer?.cancel();
    startRotationTimer();
  }

  void _runNextZikr() {
    _adhkarTimer?.cancel();
    if (state.adhkarIndex >= state.adhkarMessages.length) {
      startRotationTimer();
      onAdhkarCompleted?.call();
      return;
    }

    final duration = state.adhkarMessages[state.adhkarIndex].duration;
    _adhkarTimer = Timer(duration, () {
      if (isClosed) return;
      emit(state.copyWith(adhkarIndex: state.adhkarIndex + 1));
      _runNextZikr();
    });
  }

  @override
  Future<void> close() {
    _rotationTimer?.cancel();
    _adhkarTimer?.cancel();
    _watchdogTimer?.cancel();
    _versionSubscription?.cancel();
    _collectionsSubscription?.cancel();
    _liveDisplaySubscription?.cancel();
    _displaySettingsSubscription?.cancel();
    return super.close();
  }
}

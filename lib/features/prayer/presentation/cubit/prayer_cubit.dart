import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masjid_app/core/enums/app_state_enum.dart';
import 'package:masjid_app/core/utils/date_helper.dart';
import 'package:masjid_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:masjid_app/features/prayer/presentation/cubit/prayer_state.dart';

class PrayerCubit extends Cubit<PrayerState> {
  final PrayerRepository _repository;
  AudioPlayer? _audioPlayer;

  Timer? _clockTimer;
  Timer? _adhanDelayTimer;
  Timer? _iqamaExitTimer;
  StreamSubscription<Map<String, int>>? _iqamaSubscription;
  StreamSubscription<int>? _hijriOffsetSubscription;
  StreamSubscription<double>? _dateFontSizeSubscription;

  DateTime? _lastLoadedDay;
  DateTime? _adhanTriggeredAt;
  String? _lastTriggeredPrayer;
  int _lastTickSecond = -1;

  final void Function(String prayerName, {required bool isManual})?
      onStartAdhkarRequested;
  final void Function()? onEnsureVideoPlaying;

  PrayerCubit(
    this._repository, {
    this.onStartAdhkarRequested,
    this.onEnsureVideoPlaying,
  }) : super(PrayerState(now: DateTime.now()));

  Future<void> _playAdhanAudio() async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.release);
      await _audioPlayer!.stop();
      await _audioPlayer!.play(AssetSource('audios/adhan.mp3'));
    } catch (_) {}
  }

  Future<void> _stopAdhanAudio() async {
    try {
      await _audioPlayer?.stop();
    } catch (_) {}
  }

  Future<void> init() async {
    final prayers = await _repository.getTodayPrayers();
    final iqama = await _repository.getIqamaTimes();
    final hijriOffset = await _repository.getHijriOffset();
    DateHelper.hijriOffset = hijriOffset;

    if (isClosed) return;

    emit(
      state.copyWith(
        todayPrayerData: prayers,
        iqamaTimes: iqama,
        hijriOffset: hijriOffset,
        countdown: _repository.calculateCountdown(prayers),
      ),
    );

    _listenToIqamaChanges();
    _listenToHijriOffsetChanges();
    _listenToDateFontSizeChanges();
    _startClockTimer();
    await _restoreIqamaCountdownIfNeeded();
  }

  void _listenToIqamaChanges() {
    _iqamaSubscription?.cancel();
    _iqamaSubscription = _repository.listenToIqamaTimes().listen((newIqama) {
      if (isClosed || newIqama.isEmpty) return;
      emit(state.copyWith(iqamaTimes: newIqama));
    });
  }

  void _listenToHijriOffsetChanges() {
    _hijriOffsetSubscription?.cancel();
    _hijriOffsetSubscription =
        _repository.listenToHijriOffset().listen((newOffset) {
      if (isClosed) return;
      DateHelper.hijriOffset = newOffset;
      emit(state.copyWith(hijriOffset: newOffset));
    });
  }

  void _listenToDateFontSizeChanges() {
    _dateFontSizeSubscription?.cancel();
    _dateFontSizeSubscription =
        _repository.listenToDateFontSize().listen((newSize) {
      if (isClosed) return;
      emit(state.copyWith(dateFontSize: newSize));
    });
  }

  int _adhanOffsetMinutes(String prayerName) =>
      prayerName == 'الشروق' ? 0 : 3;

  DateTime _resolveIqamaTargetTime(String prayerName, DateTime baseAdhanTime) {
    final iqamaMinutes = state.iqamaTimes[prayerName] ?? 10;
    return baseAdhanTime.add(
      Duration(minutes: iqamaMinutes + _adhanOffsetMinutes(prayerName)),
    );
  }

  Future<void> _restoreIqamaCountdownIfNeeded() async {
    final saved = await _repository.loadSavedAdhanState();
    final savedPrayer = saved.prayerName;
    final adhanTime = saved.triggeredAt;

    if (savedPrayer == null || adhanTime == null) return;

    final now = DateTime.now();
    final iqamaTime = _resolveIqamaTargetTime(savedPrayer, adhanTime);

    if (now.isBefore(iqamaTime)) {
      _adhanTriggeredAt = adhanTime;
      if (!isClosed) {
        emit(
          state.copyWith(
            currentPrayerName: savedPrayer,
            appState: AppState.iqamaCount,
            iqamaCountdown: _calculateIqamaCountdown(savedPrayer),
          ),
        );
      }
    } else {
      await _repository.clearAdhanState();
    }
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    // الفحص كل 200 مللي ثانية مع تحديث الواجهة فقط عند تغيّر الثانية الفعلية يمنع قفز العداد ثانيتين معاً
    _clockTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (isClosed) return;
      final now = DateTime.now();
      if (now.second == _lastTickSecond) return;
      _lastTickSecond = now.second;

      final today = DateTime(now.year, now.month, now.day);
      if (_lastLoadedDay == null || today != _lastLoadedDay) {
        _lastLoadedDay = today;
        reloadPrayerTimes();
      }

      // فحص دوري كل 10 ثوانٍ للتأكد من عدم توقف الفيديو في الخلفية
      if (now.second % 10 == 0) {
        onEnsureVideoPlaying?.call();
      }

      final countdown = _repository.calculateCountdown(state.todayPrayerData);

      if (state.appState == AppState.iqamaCount) {
        final iqamaCountdown =
            _calculateIqamaCountdown(state.currentPrayerName);
        if (iqamaCountdown == '00:00') {
          _adhanTriggeredAt = null;
          _repository.clearAdhanState();
          emit(
            state.copyWith(
              now: now,
              countdown: countdown,
              iqamaCountdown: iqamaCountdown,
              appState: AppState.iqama,
              isManualAdhkar: false,
            ),
          );
          _scheduleAutoExitFromIqama();
        } else {
          emit(
            state.copyWith(
              now: now,
              countdown: countdown,
              iqamaCountdown: iqamaCountdown,
            ),
          );
        }
      } else {
        emit(state.copyWith(now: now, countdown: countdown));
      }

      _checkPrayerTime(now);
    });
  }

  void _scheduleAutoExitFromIqama() {
    _iqamaExitTimer?.cancel();
    final currentPrayer = state.currentPrayerName.isNotEmpty &&
            state.currentPrayerName != 'الشروق'
        ? state.currentPrayerName
        : _repository.getCurrentPrayerName(state.todayPrayerData);

    final int delayMinutes =
        (currentPrayer == "الفجر" || currentPrayer == "العشاء") ? 15 : 11;

    _iqamaExitTimer = Timer(Duration(minutes: delayMinutes), () {
      if (isClosed) return;
      if (state.appState == AppState.iqama && !state.isManualAdhkar) {
        onEnsureVideoPlaying?.call();
        emit(
          state.copyWith(
            appState: AppState.adhkar,
            currentPrayerName: currentPrayer,
          ),
        );
        onStartAdhkarRequested?.call(
          currentPrayer,
          isManual: false,
        );
      }
    });
  }

  String _calculateIqamaCountdown(String prayerName) {
    if (prayerName.isEmpty) return '';
    final now = DateTime.now();

    DateTime baseTime;
    if (_adhanTriggeredAt != null) {
      baseTime = _adhanTriggeredAt!;
    } else {
      if (state.todayPrayerData == null) return '';
      final timeStr = state.todayPrayerData!.times[prayerName];
      if (timeStr == null) return '';
      baseTime = _repository.parseTime(timeStr, now);
    }

    final iqamaMinutes = state.iqamaTimes[prayerName] ?? 10;
    final iqamaTime = _resolveIqamaTargetTime(prayerName, baseTime);
    final diff = iqamaTime.difference(now);

    if (diff.isNegative || diff.inSeconds <= 0) return '00:00';

    final maxSeconds = iqamaMinutes * 60;
    final totalSeconds = diff.inSeconds.clamp(0, maxSeconds);
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _checkPrayerTime(DateTime now) {
    if (state.todayPrayerData == null) return;
    // لا تقاطع شاشة الأذان أو شاشة الإقامة لو كانت الصلاة قائمة بالفعل
    if (state.appState == AppState.adhan || state.appState == AppState.iqama) {
      return;
    }

    const prayerOrder = [
      "الفجر",
      "الشروق",
      "الظهر",
      "العصر",
      "المغرب",
      "العشاء",
    ];

    for (final prayerName in prayerOrder) {
      final timeStr = state.todayPrayerData!.times[prayerName];
      if (timeStr == null) continue;
      final prayerTime = _repository.parseTime(timeStr, now);
      final diff = prayerTime.difference(now).inSeconds;

      if (diff <= 0 && diff > -60) {
        _triggerAdhan(prayerName);
      }
    }
  }

  void _triggerAdhan(String prayerName) {
    if (_lastTriggeredPrayer == prayerName) return;

    _adhanDelayTimer?.cancel();
    _iqamaExitTimer?.cancel();
    _stopAdhanAudio();
    _lastTriggeredPrayer = prayerName;
    _adhanTriggeredAt = DateTime.now();

    if (prayerName != 'الشروق') {
      _repository.saveAdhanState(prayerName, _adhanTriggeredAt!);
    }
    onEnsureVideoPlaying?.call();

    emit(
      state.copyWith(
        currentPrayerName: prayerName,
        appState: AppState.adhan,
        isManualAdhkar: false,
        isManualIqama: false,
      ),
    );

    if (prayerName != 'الشروق') {
      _playAdhanAudio();
    }

    final int delay = (prayerName == 'الشروق') ? 3 : 60 * 3;
    _adhanDelayTimer = Timer(Duration(seconds: delay), () {
      if (isClosed) return;
      _stopAdhanAudio();
      onEnsureVideoPlaying?.call();

      // الشروق ليس له إقامة ولا أذكار صلاة مفروضة؛ يعود للوضع الطبيعي بعد التنبيه
      if (prayerName == 'الشروق') {
        emit(state.copyWith(appState: AppState.normal));
        return;
      }

      final isJumuah =
          prayerName == 'الظهر' && DateTime.now().weekday == DateTime.friday;

      if (isJumuah) {
        _adhanTriggeredAt = null;
        _repository.clearAdhanState();
        emit(state.copyWith(appState: AppState.iqama));
        _iqamaExitTimer?.cancel();
        _iqamaExitTimer = Timer(const Duration(minutes: 32), () {
          if (isClosed) return;
          if (state.appState == AppState.iqama && !state.isManualAdhkar) {
            onEnsureVideoPlaying?.call();
            emit(state.copyWith(appState: AppState.adhkar));
            onStartAdhkarRequested?.call(
              prayerName,
              isManual: false,
            );
          }
        });
      } else {
        emit(
          state.copyWith(
            appState: AppState.iqamaCount,
            iqamaCountdown: _calculateIqamaCountdown(prayerName),
          ),
        );
      }
    });
  }

  void switchToIqama() {
    _adhanDelayTimer?.cancel();
    _iqamaExitTimer?.cancel();
    _stopAdhanAudio();

    final isComingFromActiveAdhanOrCountdown =
        (state.appState == AppState.adhan ||
                state.appState == AppState.iqamaCount) &&
            state.currentPrayerName.isNotEmpty &&
            state.currentPrayerName != 'الشروق';

    // مسح عداد الإقامة السابق لأن الصلاة أُقيمت بالفعل
    _adhanTriggeredAt = null;
    _repository.clearAdhanState();

    final resolvedPrayer = isComingFromActiveAdhanOrCountdown
        ? state.currentPrayerName
        : _repository.getCurrentPrayerName(state.todayPrayerData);

    // منع _checkPrayerTime من إعادة إطلاق أذان نفس الصلاة لو ضُغط الزر الأحمر في نفس دقيقة الأذان
    if (resolvedPrayer.isNotEmpty) {
      _lastTriggeredPrayer = resolvedPrayer;
    }

    emit(
      state.copyWith(
        appState: AppState.iqama,
        currentPrayerName: resolvedPrayer,
        isManualIqama: true,
        isManualAdhkar: false,
      ),
    );
    _scheduleAutoExitFromIqama();
  }

  void enterManualAdhkarState() {
    _adhanDelayTimer?.cancel();
    _iqamaExitTimer?.cancel();
    _stopAdhanAudio();
    onEnsureVideoPlaying?.call();
    emit(
      state.copyWith(
        appState: AppState.adhkar,
        isManualAdhkar: true,
        isManualIqama: false,
      ),
    );
  }

  void onAdhkarFinished() {
    onEnsureVideoPlaying?.call();

    if (_adhanTriggeredAt != null && state.currentPrayerName.isNotEmpty) {
      final now = DateTime.now();
      final iqamaTime = _resolveIqamaTargetTime(
        state.currentPrayerName,
        _adhanTriggeredAt!,
      );
      if (now.isBefore(iqamaTime)) {
        emit(
          state.copyWith(
            appState: AppState.iqamaCount,
            iqamaCountdown: _calculateIqamaCountdown(state.currentPrayerName),
            isManualAdhkar: false,
            isManualIqama: false,
          ),
        );
        return;
      }
    }

    _lastTriggeredPrayer = null;
    emit(
      state.copyWith(
        appState: AppState.normal,
        isManualAdhkar: false,
        isManualIqama: false,
      ),
    );
  }

  void switchToNormal() {
    _adhanDelayTimer?.cancel();
    _iqamaExitTimer?.cancel();
    _stopAdhanAudio();
    onEnsureVideoPlaying?.call();

    if (_adhanTriggeredAt != null && state.currentPrayerName.isNotEmpty) {
      final now = DateTime.now();
      final iqamaTime = _resolveIqamaTargetTime(
        state.currentPrayerName,
        _adhanTriggeredAt!,
      );

      if (now.isBefore(iqamaTime)) {
        emit(
          state.copyWith(
            appState: AppState.iqamaCount,
            iqamaCountdown: _calculateIqamaCountdown(state.currentPrayerName),
            isManualAdhkar: false,
            isManualIqama: false,
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        appState: AppState.normal,
        isManualAdhkar: false,
        isManualIqama: false,
      ),
    );
  }

  Future<void> reloadPrayerTimes() async {
    final prayers = await _repository.getTodayPrayers();
    if (isClosed) return;
    _lastTriggeredPrayer = null;
    emit(
      state.copyWith(
        todayPrayerData: prayers,
        countdown: _repository.calculateCountdown(prayers),
      ),
    );
  }

  @override
  Future<void> close() async {
    _clockTimer?.cancel();
    _adhanDelayTimer?.cancel();
    _iqamaExitTimer?.cancel();
    _iqamaSubscription?.cancel();
    _hijriOffsetSubscription?.cancel();
    _dateFontSizeSubscription?.cancel();
    try {
      await _audioPlayer?.dispose();
    } catch (_) {}
    return super.close();
  }
}

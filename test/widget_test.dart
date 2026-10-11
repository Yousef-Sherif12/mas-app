import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:masjid_app/core/enums/adhkar_type_enum.dart';
import 'package:masjid_app/core/enums/app_state_enum.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/core/utils/date_helper.dart';
import 'package:masjid_app/features/content/domain/entities/message.dart';
import 'package:masjid_app/features/content/domain/repositories/content_repository.dart';
import 'package:masjid_app/features/content/presentation/cubit/content_cubit.dart';
import 'package:masjid_app/features/home/presentation/screens/home_screen.dart';
import 'package:masjid_app/features/prayer/data/datasources/prayer_data_source.dart';
import 'package:masjid_app/features/prayer/data/models/day_prayer_model.dart';
import 'package:masjid_app/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:masjid_app/features/prayer/domain/entities/day_prayer.dart';
import 'package:masjid_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:masjid_app/features/prayer/presentation/cubit/prayer_cubit.dart';
import 'package:masjid_app/features/theme/domain/repositories/theme_repository.dart';
import 'package:masjid_app/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:masjid_app/features/ticker/domain/entities/ticker_message.dart';
import 'package:masjid_app/features/ticker/domain/repositories/ticker_repository.dart';
import 'package:masjid_app/features/ticker/presentation/cubit/ticker_cubit.dart';

// ---------------------------------------------------------------------------
// Fakes & Mocks for QA Testing
// ---------------------------------------------------------------------------

class FakePrayerRepository implements PrayerRepository {
  DayPrayer? todayPrayers;
  Map<String, int> iqamaTimes;
  String? savedPrayerName;
  DateTime? savedTriggeredAt;
  String currentPrayerNameOverride;
  final StreamController<Map<String, int>> iqamaStreamController =
      StreamController<Map<String, int>>.broadcast();
  final StreamController<int> hijriOffsetStreamController =
      StreamController<int>.broadcast();
  int hijriOffset = 0;

  FakePrayerRepository({
    this.todayPrayers,
    Map<String, int>? iqamaTimes,
    this.savedPrayerName,
    this.savedTriggeredAt,
    this.currentPrayerNameOverride = 'الظهر',
  }) : iqamaTimes = iqamaTimes ??
            const {
              'الفجر': 20,
              'الظهر': 15,
              'العصر': 15,
              'المغرب': 10,
              'العشاء': 15,
            };

  @override
  Future<DayPrayer?> getTodayPrayers() async => todayPrayers;

  @override
  Future<Map<String, int>> getIqamaTimes() async => iqamaTimes;

  @override
  Stream<Map<String, int>> listenToIqamaTimes() => iqamaStreamController.stream;

  @override
  Future<int> getHijriOffset() async => hijriOffset;

  @override
  Stream<int> listenToHijriOffset() => hijriOffsetStreamController.stream;

  @override
  Future<({String? prayerName, DateTime? triggeredAt})>
      loadSavedAdhanState() async {
    return (prayerName: savedPrayerName, triggeredAt: savedTriggeredAt);
  }

  @override
  Future<void> saveAdhanState(String prayerName, DateTime triggeredAt) async {
    savedPrayerName = prayerName;
    savedTriggeredAt = triggeredAt;
  }

  @override
  Future<void> clearAdhanState() async {
    savedPrayerName = null;
    savedTriggeredAt = null;
  }

  @override
  DateTime parseTime(String timeStr, DateTime date) {
    final clean = timeStr.trim().toUpperCase();
    final isPM = clean.contains('PM');
    final timePart = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = timePart.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  Map<String, dynamic> calculateCountdown(DayPrayer? todayPrayerData) {
    return {'name': 'الظهر', 'h': 1, 'm': 25, 's': 40};
  }

  @override
  String getCurrentPrayerName(DayPrayer? todayPrayerData) {
    return currentPrayerNameOverride;
  }
}

class FakeContentRepository implements ContentRepository {
  final StreamController<int> versionController =
      StreamController<int>.broadcast();
  final StreamController<List<Map<String, dynamic>>> collectionsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>?> liveDisplayController =
      StreamController<Map<String, dynamic>?>.broadcast();

  int localVersion = 1;

  @override
  Future<List<Map<String, dynamic>>> getActiveCollections() async => [
        {'id': 'quran_messages', 'label': 'قرآن', 'order': 0},
        {'id': 'hadith_messages', 'label': 'حديث', 'order': 1},
      ];

  @override
  Future<List<Message>> getCollectionMessages(String collection) async {
    if (collection == 'quran_messages') {
      return const [
        Message(
          docId: 'q1',
          type: 'quran',
          text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝',
          customDuration: Duration(seconds: 10),
        ),
        Message(
          docId: 'q2',
          type: 'quran',
          text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝',
          customDuration: Duration(seconds: 10),
        ),
      ];
    }
    return const [
      Message(
        docId: 'h1',
        type: 'hadith',
        text: 'إنما الأعمال بالنيات',
        customDuration: Duration(seconds: 10),
      ),
    ];
  }

  @override
  Future<List<Message>> getAdhkarSalah() async => const [
        Message(
          docId: 's1',
          type: 'adhkar_salah',
          text: 'أستغفر الله (ثلاثاً)',
          customDuration: Duration(seconds: 5),
        ),
      ];

  @override
  Future<List<Message>> getAdhkarSabah() async => const [
        Message(
          docId: 'sb1',
          type: 'adhkar_sabah',
          text: 'أصبحنا وأصبح الملك لله',
          customDuration: Duration(seconds: 5),
        ),
        Message(
          docId: 'sb2',
          type: 'adhkar_sabah',
          text: 'اللهم بك أصبحنا وبك أمسينا',
          customDuration: Duration(seconds: 5),
        ),
      ];

  @override
  Future<List<Message>> getAdhkarMasa() async => const [
        Message(
          docId: 'm1',
          type: 'adhkar_masa',
          text: 'أمسينا وأمسى الملك لله',
          customDuration: Duration(seconds: 5),
        ),
      ];

  @override
  Stream<int> listenToMessagesVersion() => versionController.stream;

  @override
  Stream<List<Map<String, dynamic>>> listenToCollectionsConfig() =>
      collectionsController.stream;

  @override
  Stream<Map<String, dynamic>?> listenToLiveDisplay() =>
      liveDisplayController.stream;

  @override
  Future<int> getLocalMessagesVersion() async => localVersion;

  @override
  Future<void> setLocalMessagesVersion(int version) async {
    localVersion = version;
  }

  @override
  Future<void> clearAllMessageCaches() async {}

  @override
  Future<void> clearActiveCollectionsCache() async {}

  @override
  void resetSessionCache() {}
}

class FakeThemeRepository implements ThemeRepository {
  AppThemeEnum savedTheme = AppThemeEnum.oldTheme;

  @override
  Future<AppThemeEnum> loadTheme() async => savedTheme;

  @override
  Future<void> saveTheme(AppThemeEnum theme) async {
    savedTheme = theme;
  }
}

class FakeTickerRepository implements TickerRepository {
  @override
  Stream<List<TickerMessage>> listenToTickerMessages() => Stream.value(const [
        TickerMessage(
          id: 't1',
          text: 'مرحباً بكم في بيت الله',
          active: true,
          order: 0,
        ),
        TickerMessage(
          id: 't2',
          text: 'يرجى تسوية الصفوف وإغلاق الهواتف',
          active: true,
          order: 1,
        ),
      ]);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ar', null);
  });

  // =========================================================================
  // SUITE 1: JSON Assets & Static Data Integrity QA
  // =========================================================================
  group('QA Suite 1: JSON Assets & Data Files Integrity', () {
    test('All required JSON asset files exist and contain valid non-empty JSON',
        () {
      const jsonFiles = [
        'assets/jsons/prayer_times_.json',
        'assets/jsons/iqama_times.json',
        'assets/jsons/quran_messages.json',
        'assets/jsons/hadith_messages.json',
        'assets/jsons/prayer_from_quran.json',
        'assets/jsons/thaqil.json',
        'assets/jsons/adhkar_salah.json',
        'assets/jsons/sabah_adhkar.json',
        'assets/jsons/masaa_adhkar.json',
      ];

      for (final relativePath in jsonFiles) {
        final candidate = File('../masjid_app/$relativePath');
        final file = candidate.existsSync() ? candidate : File(relativePath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing asset file: $relativePath',
        );
        final content = file.readAsStringSync();
        expect(
          content.trim().isNotEmpty,
          isTrue,
          reason: 'Empty asset file: $relativePath',
        );
        final decoded = jsonDecode(content);
        expect(decoded, isNotNull, reason: 'Invalid JSON in: $relativePath');
      }
    });

    test(
        'prayer_times_.json contains valid prayer times and every time string parses cleanly',
        () {
      final candidate = File('../masjid_app/assets/jsons/prayer_times_.json');
      final file = candidate.existsSync()
          ? candidate
          : File('assets/jsons/prayer_times_.json');
      final content = file.readAsStringSync();
      final List<dynamic> days = jsonDecode(content) as List<dynamic>;
      expect(days.length, greaterThanOrEqualTo(365));

      final fakeRepo = FakePrayerRepository();
      final sampleDate = DateTime(2026, 5, 15);

      for (final entry in days) {
        final map = Map<String, dynamic>.from(entry as Map);
        expect(map['date'], isNotNull);
        final times = Map<String, dynamic>.from(map['times'] as Map);
        for (final prayer in [
          'الفجر',
          'الشروق',
          'الظهر',
          'العصر',
          'المغرب',
          'العشاء',
        ]) {
          expect(
            times.containsKey(prayer),
            isTrue,
            reason: 'Missing $prayer on ${map['date']}',
          );
          final parsed =
              fakeRepo.parseTime(times[prayer].toString(), sampleDate);
          expect(parsed.year, sampleDate.year);
        }
      }
    });
  });

  // =========================================================================
  // SUITE 2: Domain & Repository Calculations QA
  // =========================================================================
  group('QA Suite 2: Domain & PrayerRepositoryImpl Logic', () {
    test('parseTime handles AM, PM, 12 PM (noon), and 12 AM (midnight)', () {
      final repo = FakePrayerRepository();
      final base = DateTime(2026, 10, 11);

      expect(repo.parseTime('04:35 AM', base), DateTime(2026, 10, 11, 4, 35));
      expect(repo.parseTime('12:05 PM', base), DateTime(2026, 10, 11, 12, 5));
      expect(repo.parseTime('03:20 PM', base), DateTime(2026, 10, 11, 15, 20));
      expect(repo.parseTime('12:10 AM', base), DateTime(2026, 10, 11, 0, 10));
    });

    test(
        'PrayerRepositoryImpl.getCurrentPrayerName never returns الشروق (prevents 5-min premature exit bug)',
        () {
      final now = DateTime.now();
      final fajrTime = now.subtract(const Duration(minutes: 60));
      final shorouqTime = now.subtract(const Duration(minutes: 5));
      final dhuhrTime = now.add(const Duration(hours: 4));

      String fmt(DateTime dt) {
        int h = dt.hour;
        final m = dt.minute.toString().padLeft(2, '0');
        final ampm = h >= 12 ? 'PM' : 'AM';
        if (h > 12) h -= 12;
        if (h == 0) h = 12;
        return '${h.toString().padLeft(2, '0')}:$m $ampm';
      }

      final dayPrayer = DayPrayer(
        date: '2026-10-11',
        times: {
          'الفجر': fmt(fajrTime),
          'الشروق': fmt(shorouqTime),
          'الظهر': fmt(dhuhrTime),
          'العصر': '03:30 PM',
          'المغرب': '06:00 PM',
          'العشاء': '07:30 PM',
        },
      );

      final repo = PrayerRepositoryImpl(_NoopPrayerDataSource());
      final currentPrayer = repo.getCurrentPrayerName(dayPrayer);
      expect(currentPrayer, isNot('الشروق'));
      expect(currentPrayer, equals('الفجر'));
    });

    test('DateHelper formats Arabic date, time, and Hijri date accurately', () {
      final dt = DateTime(2026, 10, 11, 14, 5);
      expect(DateHelper.formatDate(dt), '11 أكتوبر 2026');
      expect(DateHelper.formatTime(dt), '02:05 م');
      expect(DateHelper.formatHijriDate(dt), contains('هـ'));
    });
  });

  // =========================================================================
  // SUITE 3: PrayerCubit State Machine & Edge Cases QA
  // =========================================================================
  group('QA Suite 3: PrayerCubit State Machine & Timers', () {
    testWidgets(
        'Issue #2 QA: Manual Red Button (switchToIqama) stays in Iqama for full 11 minutes (Dhuhr) or 15 minutes (Fajr) and never exits early',
        (tester) async {
      String? startedAdhkarFor;
      final fakeRepo = FakePrayerRepository(
        currentPrayerNameOverride: 'الظهر',
      );
      final cubit = PrayerCubit(
        fakeRepo,
        onStartAdhkarRequested: (prayer, {required isManual}) {
          startedAdhkarFor = prayer;
        },
      );

      // Press Red button once
      cubit.switchToIqama();
      expect(cubit.state.appState, AppState.iqama);
      expect(cubit.state.currentPrayerName, 'الظهر');

      // Advance 5 minutes, then press Red button AGAIN (simulating accidental double press)
      await tester.pump(const Duration(minutes: 5));
      expect(cubit.state.appState, AppState.iqama);

      cubit.switchToIqama();
      // Advance 7 minutes (total 12 minutes since first press, but only 7 since second press!)
      await tester.pump(const Duration(minutes: 7));
      expect(
        cubit.state.appState,
        AppState.iqama,
        reason: 'Must NOT exit early before full 11 minutes from last press',
      );

      // Advance remaining 4 minutes (total 11 minutes from second press)
      await tester.pump(const Duration(minutes: 4));
      expect(cubit.state.appState, AppState.adhkar);
      expect(startedAdhkarFor, 'الظهر');

      await cubit.close();
    });

    testWidgets(
        'QA Bug Fix Verification: Pressing Red Button in normal state resolves actual current prayer instead of stale previous prayer',
        (tester) async {
      final fakeRepo = FakePrayerRepository(
        currentPrayerNameOverride: 'الفجر',
      );
      final cubit = PrayerCubit(fakeRepo);

      // 1. Morning Fajr Iqama triggered and completed
      cubit.switchToIqama();
      expect(cubit.state.currentPrayerName, 'الفجر');
      await tester.pump(const Duration(minutes: 15));
      expect(cubit.state.appState, AppState.adhkar);
      cubit.onAdhkarFinished();
      expect(cubit.state.appState, AppState.normal);

      // 2. Now it is Dhuhr time in the afternoon
      fakeRepo.currentPrayerNameOverride = 'الظهر';

      // 3. Imam presses Red button in normal mode
      cubit.switchToIqama();
      expect(
        cubit.state.currentPrayerName,
        'الظهر',
        reason:
            'Should resolve الظهر from repository instead of stale الفجر from morning',
      );

      // Should exit after 11 minutes (Dhuhr), not 15 minutes (Fajr)
      await tester.pump(const Duration(minutes: 11));
      expect(cubit.state.appState, AppState.adhkar);

      await cubit.close();
    });

    testWidgets(
        'QA Bug Fix Verification: Opening Manual Adhkar during iqamaCount then pressing 0 restores iqamaCount AND resets isManualAdhkar so Iqama still auto-exits',
        (tester) async {
      final now = DateTime.now();
      final fakeRepo = FakePrayerRepository(
        savedPrayerName: 'العصر',
        savedTriggeredAt: now.subtract(const Duration(minutes: 4)),
        iqamaTimes: const {'العصر': 15},
        currentPrayerNameOverride: 'العصر',
      );
      final cubit = PrayerCubit(fakeRepo);

      await cubit.init();
      await tester.pump();

      // Restored into iqamaCount
      expect(cubit.state.appState, AppState.iqamaCount);

      // User presses Green button (manual adhkar) during iqamaCount
      cubit.enterManualAdhkarState();
      expect(cubit.state.appState, AppState.adhkar);
      expect(cubit.state.isManualAdhkar, isTrue);

      // User presses 0 (switchToNormal) -> should return to iqamaCount with isManualAdhkar = false
      cubit.switchToNormal();
      expect(cubit.state.appState, AppState.iqamaCount);
      expect(
        cubit.state.isManualAdhkar,
        isFalse,
        reason:
            'isManualAdhkar must be reset to false when returning to iqamaCount',
      );

      await cubit.close();
    });
  });

  // =========================================================================
  // SUITE 4: ContentCubit Rotation, Sabah Adhkar x2 & Live Display QA
  // =========================================================================
  group('QA Suite 4: ContentCubit Rotation & Adhkar Rules', () {
    testWidgets(
        'Fajr post-prayer Adhkar repeats Sabah Adhkar TWICE after Salah Adhkar as requested by user',
        (tester) async {
      final repo = FakeContentRepository();
      final cubit = ContentCubit(repo);

      await cubit.init();
      await tester.pump();

      cubit.startPrayerAdhkar('الفجر');
      // 1 salah + (2 sabah * 2) = 5 messages total
      expect(cubit.state.adhkarMessages.length, 5);
      expect(cubit.state.adhkarMessages[0].docId, 's1');
      expect(cubit.state.adhkarMessages[1].docId, 'sb1');
      expect(cubit.state.adhkarMessages[2].docId, 'sb2');
      expect(cubit.state.adhkarMessages[3].docId, 'sb1');
      expect(cubit.state.adhkarMessages[4].docId, 'sb2');

      await cubit.close();
    });

    testWidgets(
        'Asr post-prayer Adhkar combines Salah Adhkar + Masa Adhkar, and completes cleanly',
        (tester) async {
      bool completed = false;
      final repo = FakeContentRepository();
      final cubit = ContentCubit(
        repo,
        onAdhkarCompleted: () => completed = true,
      );

      await cubit.init();
      await tester.pump();

      cubit.startPrayerAdhkar('العصر');
      expect(cubit.state.adhkarMessages.length, 2); // 1 salah + 1 masa

      // Each message is 5 seconds
      await tester.pump(const Duration(seconds: 5));
      expect(cubit.state.adhkarIndex, 1);
      expect(completed, isFalse);

      await tester.pump(const Duration(seconds: 5));
      expect(completed, isTrue);

      await cubit.close();
    });

    testWidgets(
        'Live Display overrides rotation immediately and resumes when disabled',
        (tester) async {
      final repo = FakeContentRepository();
      final cubit = ContentCubit(repo);

      await cubit.init();
      await tester.pump();

      expect(cubit.state.isLiveDisplay, isFalse);

      // Activate live display for hadith h1
      repo.liveDisplayController.add({
        'active': true,
        'collection': 'hadith_messages',
        'docId': 'h1',
      });
      await tester.pump();

      expect(cubit.state.isLiveDisplay, isTrue);
      expect(cubit.state.displayMessage?.text, 'إنما الأعمال بالنيات');

      // Deactivate live display
      repo.liveDisplayController.add({'active': false});
      await tester.pump();

      expect(cubit.state.isLiveDisplay, isFalse);

      await cubit.close();
    });
  });

  // =========================================================================
  // SUITE 5: Full TV UI & Remote Control Key Simulation QA
  // =========================================================================
  group('QA Suite 5: Full Screen TV Widget & Remote Control Keys Test', () {
    testWidgets(
        'Renders HomeScreen on 1920x1080 TV resolution and responds to all Remote Control buttons (Red, Green, Yellow, Blue, 0, 1..7)',
        (tester) async {
      // Configure 1920x1080 Full HD TV Screen
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prayerRepo = FakePrayerRepository(
        todayPrayers: const DayPrayer(
          date: '2026-10-11',
          times: {
            'الفجر': '04:35 AM',
            'الشروق': '06:00 AM',
            'الظهر': '12:05 PM',
            'العصر': '03:25 PM',
            'المغرب': '05:50 PM',
            'العشاء': '07:10 PM',
          },
        ),
      );
      final contentRepo = FakeContentRepository();
      final themeRepo = FakeThemeRepository();
      final tickerRepo = FakeTickerRepository();

      final themeCubit = ThemeCubit(themeRepo, enableVideoPlayer: false);
      late final PrayerCubit prayerCubit;
      final contentCubit = ContentCubit(
        contentRepo,
        onAdhkarCompleted: () => prayerCubit.onAdhkarFinished(),
      );
      prayerCubit = PrayerCubit(
        prayerRepo,
        onStartAdhkarRequested: (prayerName, {required isManual}) {
          contentCubit.startPrayerAdhkar(prayerName);
        },
        onEnsureVideoPlaying: () {},
      );
      final tickerCubit = TickerCubit(tickerRepo);

      await contentCubit.init();
      await prayerCubit.init();
      tickerCubit.startListening();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: themeCubit),
            BlocProvider.value(value: contentCubit),
            BlocProvider.value(value: prayerCubit),
            BlocProvider.value(value: tickerCubit),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify Normal Screen UI elements
      expect(find.text('مواقيت الصلاة'), findsOneWidget);
      expect(find.text('الفجر'), findsWidgets);
      expect(find.text('العشاء'), findsWidgets);

      // 1. Simulate Red Button (KeyA) -> Iqama Screen
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(prayerCubit.state.appState, AppState.iqama);
      expect(find.text('يُرجى وضع الهاتف على الصامت'), findsOneWidget);

      // 2. Simulate Green Button (KeyS) -> Manual Salah Adhkar
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.pump();

      expect(prayerCubit.state.appState, AppState.adhkar);
      expect(contentCubit.state.currentAdhkarType, AdhkarType.salah);
      expect(find.text('أستغفر الله (ثلاثاً)'), findsOneWidget);

      // 3. Simulate Yellow Button (KeyD) -> Manual Sabah Adhkar
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
      await tester.pump();

      expect(prayerCubit.state.appState, AppState.adhkar);
      expect(contentCubit.state.currentAdhkarType, AdhkarType.sabah);
      expect(find.text('أصبحنا وأصبح الملك لله'), findsOneWidget);

      // 4. Simulate Blue Button (KeyF) -> Manual Masa Adhkar
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.pump();

      expect(prayerCubit.state.appState, AppState.adhkar);
      expect(contentCubit.state.currentAdhkarType, AdhkarType.masa);
      expect(find.text('أمسينا وأمسى الملك لله'), findsOneWidget);

      // 5. Simulate Digit 0 -> Back to Normal Mode
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit0);
      await tester.pump();

      expect(prayerCubit.state.appState, AppState.normal);
      expect(find.text('مواقيت الصلاة'), findsOneWidget);

      // 6. Simulate Digits 2 & 5 -> Theme Switching
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
      await tester.pump();
      expect(themeCubit.state.currentTheme, AppThemeEnum.newLightTheme);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit5);
      await tester.pump();
      expect(themeCubit.state.currentTheme, AppThemeEnum.hajTheme);

      await themeCubit.close();
      await contentCubit.close();
      await prayerCubit.close();
      await tickerCubit.close();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}

class _NoopPrayerDataSource implements PrayerDataSource {
  @override
  Future<Map<String, int>> getIqamaTimes() async => {};

  @override
  Future<DayPrayerModel?> getTodayPrayers() async => null;

  @override
  Stream<Map<String, int>> listenToIqamaTimes() => const Stream.empty();

  @override
  Future<int> getHijriOffset() async => 0;

  @override
  Stream<int> listenToHijriOffset() => const Stream.empty();
}

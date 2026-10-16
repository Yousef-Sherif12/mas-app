import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masjid_app/core/enums/adhkar_type_enum.dart';
import 'package:masjid_app/core/enums/app_state_enum.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/core/utils/date_helper.dart';
import 'package:masjid_app/core/widgets/blur_overlay.dart';
import 'package:masjid_app/core/widgets/masjid_logo.dart';
import 'package:masjid_app/features/content/presentation/cubit/content_cubit.dart';
import 'package:masjid_app/features/content/presentation/cubit/content_state.dart';
import 'package:masjid_app/features/content/presentation/widgets/ayat_column.dart';
import 'package:masjid_app/features/prayer/presentation/cubit/prayer_cubit.dart';
import 'package:masjid_app/features/prayer/presentation/cubit/prayer_state.dart';
import 'package:masjid_app/features/prayer/presentation/screens/adhan_screen.dart';
import 'package:masjid_app/features/prayer/presentation/screens/iqama_screen.dart';
import 'package:masjid_app/features/prayer/presentation/widgets/prayer_time_column.dart';
import 'package:masjid_app/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:masjid_app/features/theme/presentation/cubit/theme_state.dart';
import 'package:masjid_app/features/ticker/presentation/widgets/bottom_ticker.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ServicesBinding.instance.keyboard.addHandler(_onGlobalKey);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ServicesBinding.instance.keyboard.removeHandler(_onGlobalKey);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // إعادة تشغيل الفيديو والدوران وطلب الـ Focus فور فتح شاشة التلفزيون من جديد
      context.read<ThemeCubit>().ensureVideoPlaying();
      context.read<ContentCubit>().startRotationTimer();
      _focusNode.requestFocus();
    }
  }

  bool _onGlobalKey(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    final keyName = event.logicalKey.debugName;
    final key = event.logicalKey;

    final prayerCubit = context.read<PrayerCubit>();
    final contentCubit = context.read<ContentCubit>();
    final themeCubit = context.read<ThemeCubit>();

    // Red button or Key A -> Switch to Iqama
    if (keyName == 'ColorF0Red' ||
        key == LogicalKeyboardKey.colorF0Red ||
        key == LogicalKeyboardKey.keyA ||
        key.keyId == 0x100070001) {
      prayerCubit.switchToIqama();
      return true;
    }

    // Green button or Key S -> Switch to Salah Adhkar
    if (keyName == 'ColorF1Green' ||
        key == LogicalKeyboardKey.colorF1Green ||
        key == LogicalKeyboardKey.keyS ||
        key.keyId == 0x100070002) {
      prayerCubit.enterManualAdhkarState();
      contentCubit.startManualAdhkar(AdhkarType.salah);
      return true;
    }

    // Yellow button or Key D -> Switch to Sabah Adhkar
    if (keyName == 'ColorF2Yellow' ||
        key == LogicalKeyboardKey.colorF2Yellow ||
        key == LogicalKeyboardKey.keyD ||
        key.keyId == 0x100070003) {
      prayerCubit.enterManualAdhkarState();
      contentCubit.startManualAdhkar(AdhkarType.sabah);
      return true;
    }

    // Blue button or Key F -> Switch to Masa Adhkar
    if (keyName == 'ColorF2Blue' ||
        key == LogicalKeyboardKey.colorF3Blue ||
        key == LogicalKeyboardKey.keyF ||
        key.keyId == 0x100070004) {
      prayerCubit.enterManualAdhkarState();
      contentCubit.startManualAdhkar(AdhkarType.masa);
      return true;
    }

    // Digit 0 -> Switch to Normal (or Iqama countdown if still active)
    if (key == LogicalKeyboardKey.digit0) {
      contentCubit.stopAdhkar();
      prayerCubit.switchToNormal();
      return true;
    }

    // Digits 1..7 -> Change Theme
    if (key == LogicalKeyboardKey.digit1) {
      themeCubit.changeTheme(AppThemeEnum.oldTheme);
      return true;
    }
    if (key == LogicalKeyboardKey.digit2) {
      themeCubit.changeTheme(AppThemeEnum.newLightTheme);
      return true;
    }
    if (key == LogicalKeyboardKey.digit3) {
      themeCubit.changeTheme(AppThemeEnum.newDarkTheme);
      return true;
    }
    if (key == LogicalKeyboardKey.digit4) {
      themeCubit.changeTheme(AppThemeEnum.theme4);
      return true;
    }
    if (key == LogicalKeyboardKey.digit5) {
      themeCubit.changeTheme(AppThemeEnum.hajTheme);
      return true;
    }
    if (key == LogicalKeyboardKey.digit6) {
      themeCubit.changeTheme(AppThemeEnum.hajTheme2);
      return true;
    }
    if (key == LogicalKeyboardKey.digit7) {
      themeCubit.changeTheme(AppThemeEnum.theme7);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final videoController = context.read<ThemeCubit>().videoController;
        final currentTheme = themeState.currentTheme;

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          descendantsAreFocusable: true,
          child: Scaffold(
            backgroundColor: Colors.black,
            extendBody: true,
            body: BlocSelector<
              PrayerCubit,
              PrayerState,
              ({AppState appState, String currentPrayerName})
            >(
              selector: (state) => (
                appState: state.appState,
                currentPrayerName: state.currentPrayerName,
              ),
              builder: (context, prayerOverlayState) {
                final appState = prayerOverlayState.appState;
                final currentPrayerName = prayerOverlayState.currentPrayerName;

                return Stack(
                  children: [
                    if (videoController != null &&
                        videoController.value.isInitialized)
                      RepaintBoundary(
                        child: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: videoController.value.size.width,
                              height: videoController.value.size.height,
                              child: VideoPlayer(videoController),
                            ),
                          ),
                        ),
                      ),
                    BlurOverlay(currentTheme: currentTheme),

                    if (appState != AppState.adhan &&
                        appState != AppState.iqama)
                      Stack(
                        children: [
                          Row(
                            children: [
                              BlocBuilder<PrayerCubit, PrayerState>(
                                builder: (context, prayerState) {
                                  final now = prayerState.now;
                                  final countdown = prayerState.countdown;
                                  return PrayerTimesAndDateColunm(
                                    hijriDate: DateHelper.formatHijriDate(now),
                                    date: DateHelper.formatDate(now),
                                    day: DateHelper.formatDay(now),
                                    fullTime: DateHelper.formatTime(now),
                                    nextPrayName:
                                        countdown['name']?.toString() ?? '-',
                                    hours: (countdown['h'] as int?) ?? 0,
                                    minutes: (countdown['m'] as int?) ?? 0,
                                    seconds: (countdown['s'] as int?) ?? 0,
                                    iqamaTime: prayerState.iqamaCountdown,
                                    appState: prayerState.appState,
                                    currentTheme: currentTheme,
                                    prayerData: prayerState.todayPrayerData,
                                    dateFontSize: prayerState.dateFontSize,
                                  );
                                },
                              ),
                              BlocBuilder<ContentCubit, ContentState>(
                                builder: (context, contentState) {
                                  return AyatColumn(
                                    currentMessage: contentState.displayMessage,
                                    appState: appState,
                                    adhkarMessages: contentState.adhkarMessages,
                                    adhkarIndex: contentState.adhkarIndex,
                                    currentTheme: currentTheme,
                                    collectionLabel:
                                        contentState.currentCollectionLabel,
                                    fontFamily: contentState.contentFontFamily,
                                  );
                                },
                              ),
                            ],
                          ),
                          Logo(currentTheme: currentTheme),
                        ],
                      ),

                    if (appState == AppState.adhan)
                      Positioned.fill(
                        child: AdhanScreen(
                          prayerName: currentPrayerName,
                          currentTheme: currentTheme,
                        ),
                      ),

                    if (appState == AppState.iqama)
                      Positioned.fill(
                        child: IqamaScreen(prayerName: currentPrayerName),
                      ),

                    if (appState == AppState.normal ||
                        appState == AppState.iqamaCount ||
                        appState == AppState.adhkar)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: RepaintBoundary(
                          child: BottomTicker(currentTheme: currentTheme),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

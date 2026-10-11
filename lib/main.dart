import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:masjid_app/firebase_options.dart';
import 'package:masjid_app/features/content/data/datasources/content_data_source.dart';
import 'package:masjid_app/features/content/data/repositories/content_repository_impl.dart';
import 'package:masjid_app/features/content/presentation/cubit/content_cubit.dart';
import 'package:masjid_app/features/home/presentation/screens/home_screen.dart';
import 'package:masjid_app/features/prayer/data/datasources/prayer_data_source.dart';
import 'package:masjid_app/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:masjid_app/features/prayer/presentation/cubit/prayer_cubit.dart';
import 'package:masjid_app/features/theme/data/repositories/theme_repository_impl.dart';
import 'package:masjid_app/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:masjid_app/features/ticker/data/repositories/ticker_repository_impl.dart';
import 'package:masjid_app/features/ticker/presentation/cubit/ticker_cubit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ar', null);
  WakelockPlus.enable();
  runApp(const MasjidApp());
}

class MasjidApp extends StatefulWidget {
  const MasjidApp({super.key});

  @override
  State<MasjidApp> createState() => _MasjidAppState();
}

class _MasjidAppState extends State<MasjidApp> {
  late final ThemeCubit _themeCubit;
  late final ContentCubit _contentCubit;
  late final PrayerCubit _prayerCubit;
  late final TickerCubit _tickerCubit;

  @override
  void initState() {
    super.initState();

    final themeRepository = ThemeRepositoryImpl();
    final contentRepository = ContentRepositoryImpl(ContentDataSource());
    final prayerRepository = PrayerRepositoryImpl(PrayerDataSource());
    final tickerRepository = TickerRepositoryImpl();

    _themeCubit = ThemeCubit(themeRepository)..initThemeAndVideo();

    _contentCubit = ContentCubit(
      contentRepository,
      onAdhkarCompleted: () {
        _prayerCubit.onAdhkarFinished();
      },
    )..init();

    _prayerCubit = PrayerCubit(
      prayerRepository,
      onStartAdhkarRequested: (prayerName, {required isManual}) {
        _contentCubit.startPrayerAdhkar(prayerName);
      },
      onEnsureVideoPlaying: () {
        _themeCubit.ensureVideoPlaying();
      },
    )..init();

    _tickerCubit = TickerCubit(tickerRepository)..startListening();
  }

  @override
  void dispose() {
    _themeCubit.close();
    _contentCubit.close();
    _prayerCubit.close();
    _tickerCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _contentCubit),
        BlocProvider.value(value: _prayerCubit),
        BlocProvider.value(value: _tickerCubit),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Tajawal',
          textTheme: const TextTheme(),
          scaffoldBackgroundColor: Colors.black,
        ),
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeScreen(),
      ),
    );
  }
}

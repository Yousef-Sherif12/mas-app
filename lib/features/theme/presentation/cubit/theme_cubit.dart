import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/features/theme/domain/repositories/theme_repository.dart';
import 'package:masjid_app/features/theme/presentation/cubit/theme_state.dart';
import 'package:video_player/video_player.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeRepository _repository;
  final bool enableVideoPlayer;
  VideoPlayerController? _videoController;
  bool _isInitializing = false;

  ThemeCubit(
    this._repository, {
    this.enableVideoPlayer = true,
  }) : super(const ThemeState());

  VideoPlayerController? get videoController => _videoController;

  Future<void> initThemeAndVideo() async {
    final savedTheme = await _repository.loadTheme();
    await _loadAndPlayVideo(savedTheme);
  }

  Future<void> _loadAndPlayVideo(AppThemeEnum theme) async {
    if (!enableVideoPlayer) {
      emit(
        state.copyWith(
          currentTheme: theme,
          isVideoInitialized: false,
          version: state.version + 1,
        ),
      );
      return;
    }

    if (_isInitializing) return;
    _isInitializing = true;

    emit(
      state.copyWith(
        currentTheme: theme,
        version: state.version + 1,
      ),
    );

    try {
      if (_videoController != null) {
        final oldController = _videoController!;
        _videoController = null;
        try {
          if (oldController.value.isInitialized) {
            await oldController.pause().timeout(const Duration(seconds: 2));
          }
          await oldController.dispose().timeout(const Duration(seconds: 2));
        } catch (_) {}
      }

      // mixWithOthers: true يمنع نظام أندرويد من إيقاف الفيديو عند تشغيل صوت الأذان
      final newController = VideoPlayerController.asset(
        theme.videoPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _videoController = newController;

      await newController.initialize().timeout(const Duration(seconds: 5));
      if (isClosed) {
        await newController.dispose().timeout(const Duration(seconds: 2));
        return;
      }

      await newController.setLooping(true);
      await newController.setVolume(0);
      await newController.play();

      emit(
        state.copyWith(
          currentTheme: theme,
          isVideoInitialized: true,
          version: state.version + 1,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            currentTheme: theme,
            isVideoInitialized: false,
            version: state.version + 1,
          ),
        );
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> changeTheme(AppThemeEnum newTheme) async {
    if (state.currentTheme == newTheme) return;

    await _repository.saveTheme(newTheme);
    await _loadAndPlayVideo(newTheme);
  }

  Future<void> ensureVideoPlaying() async {
    if (!enableVideoPlayer || _isInitializing) return;
    final controller = _videoController;
    if (controller == null) {
      await _loadAndPlayVideo(state.currentTheme);
      return;
    }

    // لو حدث خطأ في الهاردوير ديكودر بعد قفل الشاشة وفتحها، أعد تهيئة الفيديو بالكامل
    if (controller.value.hasError || !controller.value.isInitialized) {
      await _loadAndPlayVideo(state.currentTheme);
      return;
    }

    if (!controller.value.isPlaying) {
      try {
        await controller.play();
      } catch (_) {
        await _loadAndPlayVideo(state.currentTheme);
      }
    }
  }

  @override
  Future<void> close() async {
    final controller = _videoController;
    _videoController = null;
    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.dispose().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    return super.close();
  }
}

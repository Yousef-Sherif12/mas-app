import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';

class AdhanScreen extends StatefulWidget {
  final String prayerName;
  final AppThemeEnum currentTheme;

  const AdhanScreen({
    super.key,
    required this.prayerName,
    required this.currentTheme,
  });

  @override
  State<AdhanScreen> createState() => _AdhanScreenState();
}

class _AdhanScreenState extends State<AdhanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.currentTheme.adhanTextColor;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "حان الآن موعد أذان ${widget.prayerName}",
            style: TextStyle(
              color: textColor,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          FadeTransition(
            opacity: _animation,
            child: Text(
              "يُرفع الآن الأذان",
              style: TextStyle(
                color: textColor,
                fontSize: 60,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

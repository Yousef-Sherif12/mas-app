import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/core/widgets/custom_line.dart';
import 'package:masjid_app/features/ticker/presentation/cubit/ticker_cubit.dart';
import 'package:masjid_app/features/ticker/presentation/cubit/ticker_state.dart';

class BottomTicker extends StatelessWidget {
  const BottomTicker({super.key, required this.currentTheme});

  final AppThemeEnum currentTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Column(
        children: [
          Line(height: 1, currentTheme: currentTheme),
          const SizedBox(height: 4),
          Expanded(
            child: BlocBuilder<TickerCubit, TickerState>(
              builder: (context, state) {
                final messages = state.activeMessages;
                if (messages.isEmpty) {
                  return const SizedBox();
                }

                const separator = '            .            ';
                final text =
                    messages.map((e) => e.text).join(separator) + separator;

                return Marquee(
                  key: ValueKey(text),
                  text: text,
                  style: TextStyle(
                    color: currentTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  scrollAxis: Axis.horizontal,
                  textDirection: TextDirection.rtl,
                  velocity: 45,
                  accelerationCurve: Curves.linear,
                  decelerationCurve: Curves.linear,
                  pauseAfterRound: Duration.zero,
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Line(height: 1, currentTheme: currentTheme),
        ],
      ),
    );
  }
}

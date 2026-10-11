import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/core/enums/app_state_enum.dart';
import 'package:masjid_app/core/enums/app_theme_enum.dart';
import 'package:masjid_app/core/widgets/custom_line.dart';
import 'package:masjid_app/features/content/domain/entities/message.dart';

class AyatColumn extends StatelessWidget {
  const AyatColumn({
    super.key,
    required this.currentMessage,
    required this.appState,
    required this.adhkarMessages,
    required this.adhkarIndex,
    required this.currentTheme,
    required this.collectionLabel,
  });

  final String collectionLabel;
  final Message? currentMessage;
  final AppState appState;
  final List<Message> adhkarMessages;
  final int adhkarIndex;
  final AppThemeEnum currentTheme;

  List<TextSpan> _parseText(String text) {
    final List<TextSpan> spans = [];
    String buffer = '';

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '۝') {
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer));
          buffer = '';
        }

        spans.add(
          const TextSpan(
            text: '۝',
            style: TextStyle(fontFamily: 'AmiriQuran'),
          ),
        );
      } else {
        buffer += char;
      }
    }

    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdhkarMode = appState == AppState.adhkar;
    final Message? displayMessage = isAdhkarMode
        ? (adhkarIndex < adhkarMessages.length
              ? adhkarMessages[adhkarIndex]
              : null)
        : currentMessage;

    final Color textColor = currentTheme.textColor;

    return Expanded(
      flex: 7,
      child: Container(
        margin: const EdgeInsets.only(right: 0, left: 0, top: 10, bottom: 42),
        decoration: BoxDecoration(
          color: currentTheme.panelBackgroundColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Line(height: 1, currentTheme: currentTheme),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAdhkarMode
                        ? displayMessage?.title ?? "أذكار"
                        : collectionLabel.isNotEmpty
                        ? collectionLabel
                        : displayMessage?.title ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 35,
                    ),
                  ),
                ],
              ),
              Line(currentTheme: currentTheme),
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 2000),
                    layoutBuilder:
                        (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final bool isInAnimation =
                              child.key == ValueKey(displayMessage?.text ?? '');

                          final begin = isInAnimation
                              ? const Offset(-1.0, 0.0)
                              : const Offset(1.0, 0.0);
                          const end = Offset.zero;

                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: begin,
                              end: end,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutQuart,
                              ),
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    child: displayMessage == null
                        ? const SizedBox(key: ValueKey('empty'))
                        : LayoutBuilder(
                            key: ValueKey(displayMessage.text),
                            builder: (context, constraints) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: AutoSizeText.rich(
                                          TextSpan(
                                            children: _parseText(
                                              displayMessage.text,
                                            ),
                                            style: TextStyle(
                                              color: textColor,
                                              fontFamily: 'Tajawal',
                                              height: 1.4,
                                              fontWeight: FontWeight.bold,
                                              fontSize: displayMessage
                                                  .calculateFontSize,
                                            ),
                                          ),
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                          maxFontSize:
                                              displayMessage.calculateFontSize,
                                          minFontSize: 5,
                                          stepGranularity: 1,
                                          maxLines: 15,
                                        ),
                                      ),
                                      if (displayMessage.fadl != null &&
                                          displayMessage.fadl!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            displayMessage.fadl!,
                                            textAlign: TextAlign.center,
                                            textDirection: TextDirection.rtl,
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      if (displayMessage.subText != null &&
                                          displayMessage.subText!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            displayMessage.subText!,
                                            textAlign: TextAlign.center,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              Line(height: 1, currentTheme: currentTheme),
            ],
          ),
        ),
      ),
    );
  }
}

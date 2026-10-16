class Message {
  final String type;
  final String text;
  final String? subText;
  final String? fadl;
  final double? fontSize;
  final Duration? customDuration;
  final String? docId;

  const Message({
    required this.type,
    required this.text,
    this.subText,
    this.fadl,
    this.fontSize,
    this.customDuration,
    this.docId,
  });

  String get title {
    switch (type.trim().toLowerCase()) {
      case "quran":
        return "قال الله تعالى";
      case "hadith":
        return "قال النبي ﷺ";
      case "fani":
        return "فإني قريب";
      case "adhkar_salah":
        return "الأذكارُ النبويّة بَعْدَ الصلاة";
      case "adhkar_sabah":
        return "أذكار الصباح";
      case "adhkar_masa":
        return "أذكار المساء";
      case "prayer_from_quran":
      case "prayer":
        return "أدعية من القرآن والسنة";
      case "thaqil":
        return "ثَقِّلْ مَوَازِينَكَ";
      default:
        return '';
    }
  }

  Duration get duration {
    if (customDuration != null) return customDuration!;
    final int length = text.length + (fadl?.length ?? 0);
    if (length < 80) return const Duration(seconds: 5);
    if (length < 150) return const Duration(seconds: 8);
    if (length < 250) return const Duration(seconds: 12);
    return const Duration(seconds: 16);
  }

  double get calculateFontSize {
    if (fontSize != null) return fontSize!;
    final length = text.length;
    if (length < 50) return 65;
    if (length < 100) return 60;
    if (length < 200) return 55;
    if (length < 350) return 50;
    return 32;
  }
}

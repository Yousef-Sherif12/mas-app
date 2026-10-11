import 'package:masjid_app/features/content/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.type,
    required super.text,
    super.subText,
    super.fadl,
    super.fontSize,
    super.customDuration,
    super.docId,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    Duration? parsedDuration;

    if (map['customDuration'] != null &&
        map['customDuration'].toString().isNotEmpty) {
      final List<String> parts = map['customDuration'].toString().split(':');
      if (parts.length == 3) {
        parsedDuration = Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
          seconds: double.tryParse(parts[2])?.toInt() ?? 0,
        );
      }
    }

    if (parsedDuration == null && map['duration'] != null) {
      final d = num.tryParse(map['duration'].toString());
      // Ignore dummy 3-second placeholder on long texts so Message.duration calculates proper reading time
      final textLen =
          (map['text']?.toString().length ?? 0) +
          (map['fadl']?.toString().length ?? 0);
      if (d != null && !(d == 3 && textLen >= 80)) {
        parsedDuration = Duration(seconds: d.toInt());
      }
    }

    return MessageModel(
      type: map['type']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      subText: map['subText']?.toString(),
      fadl: map['fadl']?.toString(),
      fontSize: double.tryParse(map['fontSize']?.toString() ?? ''),
      docId: map['id']?.toString(),
      customDuration: parsedDuration,
    );
  }
}

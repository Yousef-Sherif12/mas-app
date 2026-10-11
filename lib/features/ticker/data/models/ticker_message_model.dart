import 'package:masjid_app/features/ticker/domain/entities/ticker_message.dart';

class TickerMessageModel extends TickerMessage {
  const TickerMessageModel({
    required super.id,
    required super.text,
    required super.active,
    required super.order,
  });

  factory TickerMessageModel.fromMap(Map<String, dynamic> map) {
    return TickerMessageModel(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      active: map['active'] as bool? ?? true,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }
}

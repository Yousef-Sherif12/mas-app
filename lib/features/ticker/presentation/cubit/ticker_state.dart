import 'package:masjid_app/features/ticker/domain/entities/ticker_message.dart';

class TickerState {
  final List<TickerMessage> messages;

  const TickerState({this.messages = const []});

  List<TickerMessage> get activeMessages =>
      messages.where((e) => e.active).toList();
}

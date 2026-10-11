import 'package:masjid_app/features/ticker/domain/entities/ticker_message.dart';

abstract class TickerRepository {
  Stream<List<TickerMessage>> listenToTickerMessages();
}

class TickerMessage {
  final String id;
  final String text;
  final bool active;
  final int order;

  const TickerMessage({
    required this.id,
    required this.text,
    required this.active,
    required this.order,
  });
}

class Sale {
  final int saleId;
  final String name;
  final double totalPrice;
  final double oldPrice;
  final bool isBundle;
  final bool active;
  final DateTime startDate;
  final DateTime endDate;

  Sale({
    required this.saleId,
    required this.name,
    required this.totalPrice,
    required this.oldPrice,
    required this.isBundle,
    required this.active,
    required this.startDate,
    required this.endDate,
  });
}

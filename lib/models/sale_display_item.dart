class SaleDisplayItem {
  final String id;
  final String name;
  final double oldPrice;
  final double newPrice;
  final List<String>? productIds;
  final List<String> productNames;
  final List<double>? productPrices;
  final List<int>? quantities;
  final bool active;

  SaleDisplayItem({
    required this.id,
    required this.name,
    required this.oldPrice,
    required this.newPrice,
    this.productIds,
    required this.productNames,
    this.productPrices,
    this.quantities,
    required this.active,
  });
}

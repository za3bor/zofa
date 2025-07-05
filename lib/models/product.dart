class Product {
  final int id;
  final String name;
  final double price;
  bool stock;
  bool? isSeeds;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.isSeeds,
  });
}

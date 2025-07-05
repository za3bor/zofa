import 'package:zofa/models/product.dart';

class SaleItem {
  final int? saleItemId;
  int quantity;
  final Product product;

  SaleItem({
    this.saleItemId,
    required this.quantity,
    required this.product,
  });
}
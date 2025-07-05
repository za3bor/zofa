import 'package:zofa/models/sale_item.dart';

class BundleSale {
  final int saleId;
  final String saleName;
  final double totalPrice;
  final double oldPrice;
  final List<SaleItem> items;
  final bool active;

  BundleSale({
    required this.saleId,
    required this.saleName,
    required this.totalPrice,
    required this.oldPrice,
    required this.items,
    required this.active,
  });
}

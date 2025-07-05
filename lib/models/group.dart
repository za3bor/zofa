import 'package:zofa/models/sale_item.dart';

class Group {
  final int groupId;
  final double groupPrice;
  final double oldPrice;
  final int requiredQuantity;
  final List<SaleItem> items;

  Group({
    required this.groupId,
    required this.groupPrice,
    required this.oldPrice,
    required this.requiredQuantity,
    required this.items,
  });
}
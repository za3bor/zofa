class ProductOrders {
  const ProductOrders({
    required this.id,
    required this.orderDetails,
    required this.phoneNumber,
    required this.userName,
    required this.status,
    required this.totalPrice,
    required this.email,
  });
  final int id;
  final String userName;
  final String phoneNumber;
  final String orderDetails;
  final double totalPrice;
  final String status;
  final String email;
}

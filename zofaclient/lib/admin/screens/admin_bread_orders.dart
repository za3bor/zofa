import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/models/bread_orders.dart';
import 'package:zofa_client/constant.dart';

class AdminBreadOrdersScreen extends StatefulWidget {
  final String day;

  const AdminBreadOrdersScreen({
    super.key,
    required this.day,
  });

  @override
  State<AdminBreadOrdersScreen> createState() {
    return _AdminBreadOrdersScreenState();
  }
}

class _AdminBreadOrdersScreenState extends State<AdminBreadOrdersScreen> {
  List<BreadOrders> _breadOrders = [];
  Map<String, int> breadQuantityMap = {};
  bool buttonEnabled = true;
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> getOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://$ipAddress:3000/api/getAllBreadOrders?day=${widget.day}'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _breadOrders = jsonData.map((item) {
            return BreadOrders(
              id: item['id'],
              userName: item['username'],
              phoneNumber: item['phone_number'],
              totalPrice: double.parse(item['total_price'].toString()),
              orderDetails: item['order_details'],
              status: item['status'],
            );
          }).toList();

          // Aggregate bread quantities
          breadQuantityMap.clear();
          for (var order in _breadOrders) {
            var orderDetails = order.orderDetails;

            if (orderDetails.isNotEmpty) {
              List<String> items = orderDetails.split('\n');
              for (var item in items) {
                List<String> parts = item.split(':');
                if (parts.length == 2) {
                  String breadName = parts[0].trim();
                  int quantity = int.tryParse(parts[1].trim()) ?? 0;
                  breadQuantityMap.update(breadName, (existingQuantity) {
                    return existingQuantity + quantity;
                  }, ifAbsent: () => quantity);
                }
              }
            }
          }
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _breadOrders = [];
          breadQuantityMap.clear();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load bread orders.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה בטעינת הנתונים. נסה שוב.';
        _isLoading = false;
      });
      _showSnackbar(_errorMessage!);
    }
  }

  @override
  void initState() {
    super.initState();
    getOrders();
  }

// Function to delete bread order
  Future<void> deleteOrder(int orderId) async {
    try {
      setState(() {
        buttonEnabled = false;
      });

      final response = await http.delete(
        Uri.parse('http://$ipAddress:3000/api/deleteBreadOrder/$orderId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _breadOrders.removeWhere(
              (order) => order.id == orderId); // Remove the order from the list
        });
        _showSnackbar('ההזמנה נמחקה בהצלחה.');
      } else {
        throw Exception('Failed to delete bread order.');
      }
    } catch (e) {
      _showSnackbar('שגיאה במחיקת ההזמנה.');
    } finally {
      setState(() {
        buttonEnabled = true;
      });
    }
  }

  Future<void> changeStatus(int orderId, String newStatus) async {
    try {
      setState(() {
        buttonEnabled = false;
      });

      final response = await http.post(
        Uri.parse('http://$ipAddress:3000/api/setBreadOrderStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': orderId,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final orderIndex =
              _breadOrders.indexWhere((order) => order.id == orderId);
          if (orderIndex != -1) {
            _breadOrders[orderIndex] = BreadOrders(
              id: _breadOrders[orderIndex].id,
              userName: _breadOrders[orderIndex].userName,
              phoneNumber: _breadOrders[orderIndex].phoneNumber,
              totalPrice: _breadOrders[orderIndex].totalPrice,
              orderDetails: _breadOrders[orderIndex].orderDetails,
              status: newStatus.toString(),
            );
          }
        });
      } else {
        throw Exception('Failed to update order status.');
      }
    } catch (e) {
      _showSnackbar('שגיאה בעדכון הסטטוס.');
    } finally {
      setState(() {
        buttonEnabled = true;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('הזמנות לחם ליום ${widget.day} ',
            textDirection: TextDirection.rtl),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                )
              : _breadOrders.isEmpty
                  ? const Center(
                      child: Text(
                        '.אין הזמנות זמינות להיום',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            'סיכום כמות לחמים להיום:',
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        ...breadQuantityMap.entries.map((entry) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5.0),
                            color: Colors.grey[200],
                            child: ListTile(
                              title: Text(
                                '${entry.key}: ${entry.value} יחידות',
                                textDirection: TextDirection.rtl,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        const Text(
                          'הזמנות לחם:',
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _breadOrders.length,
                          itemBuilder: (context, index) {
                            final order = _breadOrders[index];
                            // Determine button states based on the order status
                            bool isReady = order.status == 'מוכן';
                            bool isShipped = order.status == 'שלח';

                            return Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              elevation: 5,
                              shadowColor: Colors.grey.withOpacity(0.3),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('שם משתמש: ${order.userName}'),
                                      Text('טלפון: ${order.phoneNumber}'),
                                      Text('פרטי הזמנה: ${order.orderDetails}'),
                                      Text(
                                          'סכום סופי: ₪${order.totalPrice.toStringAsFixed(2)}'),
                                      Text('סטטוס: ${order.status}'),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            onPressed: isShipped || isReady
                                                ? null
                                                : () {
                                                    changeStatus(
                                                        order.id, 'מוכן');
                                                  },
                                            child: const Text('מוכן'),
                                          ),
                                          const SizedBox(width: 8.0),
                                          ElevatedButton(
                                            onPressed: isShipped
                                                ? null
                                                : () {
                                                    changeStatus(
                                                        order.id, 'שלח');
                                                  },
                                            child: const Text('שלח'),
                                          ),
                                          const SizedBox(width: 8.0),
                                          ElevatedButton(
                                            onPressed: () {
                                              deleteOrder(
                                                  order.id); // Call deleteOrder
                                            },
                                            child: const Text('מחק'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
    );
  }
}

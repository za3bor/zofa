import 'package:http/http.dart' as http;
import 'package:zofa_client/models/bread_orders.dart';
import 'package:zofa_client/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        Uri.parse('http://$ipAddress/api/getAllBreadOrders?day=${widget.day}'),
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
        Uri.parse('http://$ipAddress/api/deleteBreadOrder/$orderId'),
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
        Uri.parse('http://$ipAddress/api/setBreadOrderStatus'),
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

  void sendWhatsApp(String phoneNumber, String message) async {
    final uri = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not send WhatsApp message';
    }
  }

  // Function to send notification to backend
  Future<void> sendNotification(
      String phoneNumber, String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/sendNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackbar('ההודעה נשלחה בהצלחה');
      } else {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      _showSnackbar('שגיאה בשליחת ההודעה: ${e.toString()}');
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
      appBar: CustomAppBar(
        title: 'הזמנות לחם ליום ${widget.day} ',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                )
              : _breadOrders.isEmpty
                  ? Center(
                      child: Text(
                        '.אין הזמנות זמינות להיום',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: ListView(
                        padding: EdgeInsets.all(16.0.w),
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0.h),
                            child: Text(
                              'סיכום כמות לחמים להיום:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          ...breadQuantityMap.entries.map((entry) {
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0.w),
                              child: ListTile(
                                title: Text(
                                  '${entry.key}: \n ${entry.value} יחידות',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10.h, horizontal: 16.w),
                              ),
                            );
                          }),
                          SizedBox(height: 20.h),
                          Text(
                            'הזמנות לחם:',
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          SizedBox(height: 10.h),
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
                                margin: EdgeInsets.symmetric(vertical: 10.0.h),
                                child: Padding(
                                  padding: EdgeInsets.all(16.0.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'שם משתמש: ${order.userName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        'טלפון: ${order.phoneNumber}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        'פרטי הזמנה: ${order.orderDetails}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        'סכום סופי: ₪${order.totalPrice.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        'סטטוס: ${order.status}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: isShipped
                                                  ? Colors.green
                                                  : isReady
                                                      ? Colors.blue
                                                      : Colors.black,
                                            ),
                                      ),
                                      SizedBox(height: 10.h),
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
                                          SizedBox(width: 10.0.w),
                                          ElevatedButton(
                                            onPressed: isShipped
                                                ? null
                                                : () {
                                                    changeStatus(
                                                        order.id, 'שלח');
                                                    sendNotification(
                                                        order.phoneNumber,
                                                        'ההזמנה שלך יצאה למשלוח',
                                                        'שלום ${order.userName}, ההזמנה שלך יצאה למשלוח');
                                                    sendWhatsApp(
                                                        order.phoneNumber,
                                                        'ההזמנה מוכנה');
                                                  },
                                            child: const Text('שלח'),
                                          ),
                                          SizedBox(width: 10.0.w),
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}

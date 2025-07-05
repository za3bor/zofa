import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zofa/constant.dart';
import 'package:zofa/models/sale_display_item.dart';
import 'package:http/http.dart' as http;

class SaleDetailsAdminScreen extends StatefulWidget {
  final int saleId;

  const SaleDetailsAdminScreen({super.key, required this.saleId});

  @override
  State<SaleDetailsAdminScreen> createState() => _SaleDetailsAdminScreenState();
}

class _SaleDetailsAdminScreenState extends State<SaleDetailsAdminScreen> {
  final PageController _pageController = PageController();
  SaleDisplayItem? sale;
  bool _loading = true;
  String? _error;

  // Additional fields for chooseXofN
  String? dealType;
  int? chooseCount;
  double? groupPrice;

  @override
  void initState() {
    super.initState();
    fetchSaleDetails();
  }

  Future<void> _toggleSaleActive() async {
    if (sale == null) return;

    final newStatus = !(sale!.active);

    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/toggleSaleActive/${widget.saleId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'active': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          sale = SaleDisplayItem(
            id: sale!.id,
            name: sale!.name,
            oldPrice: sale!.oldPrice,
            newPrice: sale!.newPrice,
            productIds: sale!.productIds,
            productNames: sale!.productNames,
            productPrices: sale!.productPrices,
            quantities: sale!.quantities,
            active: newStatus,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'הסטטוס עודכן ל: ${newStatus ? "פעיל" : "לא פעיל"}',
              ),
            ),
          );
        }
      } else {
        throw Exception('סטטוס לא עודכן');
      }
    } catch (e) {
      setState(() {
        _error = "שגיאה: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה: $e')));
      }
    }
  }

  Future<void> _deleteSale() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('אישור מחיקה'),
            content: const Text(
              'האם אתה בטוח שברצונך למחוק מבצע זה? פעולה זו אינה הפיכה.',
            ),
            actions: [
              TextButton(
                child: const Text('ביטול'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('מחק'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://$ipAddress/api/deleteSale/${widget.saleId}'),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('מבצע נמחק בהצלחה')));
          Navigator.of(context).pop(); // Go back after successful delete
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _error = "המבצע לא נמצא למחיקה.";
          _loading = false;
        });
      } else {
        setState(() {
          _error = "שגיאה במחיקת המבצע.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "שגיאה: $e";
        _loading = false;
      });
    }
  }

  Future<void> fetchSaleDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/getSaleDetails/${widget.saleId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        setState(() {
          dealType = data['dealType'];
          if (dealType == "chooseXofN") {
            chooseCount = data['chooseCount'];
            groupPrice = (data['groupPrice'] ?? 0).toDouble();
          }

          sale = SaleDisplayItem(
            id: data['saleId'].toString(),
            name: data['name'] ?? '',
            oldPrice: (data['oldPrice'] ?? 0).toDouble(),
            newPrice: (data['newPrice'] ?? 0).toDouble(),
            productIds:
                items.map((item) => item['productId'].toString()).toList(),
            productNames:
                items.map((item) => item['productName'].toString()).toList(),
            productPrices: List<double>.from(
              items.map((item) => (item['productPrice'] ?? 0).toDouble()),
            ),
            quantities:
                items.map((item) => (item['quantity'] ?? 1) as int).toList(),
            active: data['active'],
          );
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load sale details.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("פרטי מבצע")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("פרטי מבצע")),
        body: Center(child: Text(_error!)),
      );
    }

    final s = sale!;

    return Scaffold(
      appBar: CustomAppBar(title: s.name),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// === IMAGES CAROUSEL ===
              if (s.productIds != null && s.productIds!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: s.productIds!.length,
                      itemBuilder: (context, index) {
                        final productId = s.productIds![index];
                        return CachedNetworkImage(
                          imageUrl:
                              'https://d1qq705dywrog2.cloudfront.net/images/$productId.jpeg',
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                ),
        
              if (s.productIds != null && s.productIds!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: s.productIds!.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Theme.of(context).primaryColor,
                      dotColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
        
              /// === SALE DETAILS CARD ===
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "₪${s.oldPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "₪${s.newPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (dealType != null)
                        Text(
                          "סוג מבצע: ${dealType == "chooseXofN" ? "בחר $chooseCount מתוך רשימה" : dealType}",
                          style: const TextStyle(fontSize: 18),
                        ),
                      if (groupPrice != null)
                        Text(
                          "מחיר קבוצתי: ₪${groupPrice!.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18),
                        ),
                    ],
                  ),
                ),
              ),
        
              const SizedBox(height: 24),
        
              /// === PRODUCTS LIST CARD ===
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "מוצרים כלולים:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: s.productNames.length,
                        itemBuilder: (context, index) {
                          final name = s.productNames[index];
                          final price = s.productPrices?[index] ?? 0;
                          final quantity = s.quantities?[index] ?? 1;
        
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("- $name (x$quantity)")),
                                Text("₪${price.toStringAsFixed(2)}"),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
        
              const SizedBox(height: 24),
        
              /// === ACTION BUTTONS ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('מחק מבצע'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _deleteSale,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        sale!.active ? Icons.visibility_off : Icons.visibility,
                      ),
                      label: Text(sale!.active ? 'הפוך ללא פעיל' : 'הפוך לפעיל'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _toggleSaleActive,
                    ),
                  ),
                ],
              ),
        
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

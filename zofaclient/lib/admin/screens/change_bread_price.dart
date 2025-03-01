import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/models/bread.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BreadPriceUpdateScreen extends StatefulWidget {
  const BreadPriceUpdateScreen({super.key});

  @override
  State<BreadPriceUpdateScreen> createState() => _BreadPriceUpdateScreenState();
}

class _BreadPriceUpdateScreenState extends State<BreadPriceUpdateScreen> {
  late List<Bread> breads;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBreads();
  }

  // Fetch all breads from the API
  Future<void> fetchBreads() async {
    final response =
        await http.get(Uri.parse('http://$ipAddress/api/showAllBreadTypes'));

    if (response.statusCode == 200) {
      final List<dynamic> breadJson = json.decode(response.body);
      setState(() {
        breads = breadJson.map((json) {
          return Bread(
              id: json['id'],
              name: json['name'],
              price: double.parse(json['price'].toString()),
              quantity: int.parse(json['quantity'].toString()));
        }).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load breads');
    }
  }

  // Update the price of the bread
  Future<void> updatePrice(int id, double newPrice) async {
    final response = await http.post(
      Uri.parse('http://$ipAddress/api/updateBreadPrice/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'newPrice': newPrice}),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('מחיר עודכן בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      fetchBreads(); // Reload the bread list after price update
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בעדכון המחיר'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('עדכון מחירים'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
                padding: EdgeInsets.all(
                    16.0.w), // Add padding around the whole body
                child: ListView.builder(
                  itemCount: breads.length,
                  itemBuilder: (context, index) {
                    final bread = breads[index];
                    TextEditingController priceController =
                        TextEditingController(text: bread.price.toString());
            
                    return Card(
                      elevation: 8,
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.w),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                            16.0.w), // Padding inside the card
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bread.name,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'כמות: ${bread.quantity}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 140.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextField(
                                    controller: priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'מחיר',
                                      labelStyle: const TextStyle(
                                        color: Colors.brown,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.sp),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.brown,
                                        ),
                                        borderRadius: BorderRadius.circular(8.sp),
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      final newPrice =
                                          double.tryParse(priceController.text);
                                      if (newPrice != null) {
                                        updatePrice(bread.id, newPrice);
                                      }
                                    },
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Icon(
                                        Icons.save,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ),
    );
  }
}

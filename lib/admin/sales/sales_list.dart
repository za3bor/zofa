import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/admin/sales/sale_details.dart';
import 'package:zofa/constant.dart';
import 'package:zofa/models/sale.dart';

class SalesButtonsScreen extends StatefulWidget {
  const SalesButtonsScreen({super.key});
  @override
  State<SalesButtonsScreen> createState() => _SalesButtonsScreenState();
}

class _SalesButtonsScreenState extends State<SalesButtonsScreen> {
  late Future<List<Sale>> _salesFuture;

  Future<List<Sale>> fetchSales() async {
    final response = await http.get(
      Uri.parse('http://$ipAddress/api/getAllSales'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) {
        return Sale(
          saleId: json['sale_id'],
          name: json['name'] ?? '',
          totalPrice: double.parse(json['total_price']),
          oldPrice: double.parse(json['old_price']),
          isBundle: json['is_bundle'] == 1,
          active: json['active'] == 1,
          startDate: DateTime.parse(json['start_date']),
          endDate: DateTime.parse(json['end_date']),
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch sales');
    }
  }

  @override
  void initState() {
    super.initState();
    _salesFuture = fetchSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'מבצעים'),
      body: FutureBuilder<List<Sale>>(
        future: _salesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('שגיאה בטעינת מבצעים'));
          }

          final sales = snapshot.data ?? [];
          if (sales.isEmpty) return Center(child: Text('אין מבצעים להצגה'));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children:
                  sales.map((sale) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SaleDetailsAdminScreen(
                                    saleId: sale.saleId,
                                  ),
                            ),
                          );
                        },
                        child: Text(sale.name, style: TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}

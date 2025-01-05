import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/models/coupon.dart'; // Ensure your Coupon model is defined correctly
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/widgets/snow_layer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() {
    return _CouponsScreenState();
  }
}

class _CouponsScreenState extends State<CouponsScreen> {
  final List<Coupon> _coupons = []; // List to store Coupon objects
  final TextEditingController _codeController =
      TextEditingController(); // Controller for coupon code input
  final TextEditingController _percentageController =
      TextEditingController(); // Controller for percentage input

  @override
  void initState() {
    super.initState();
    _fetchCoupons(); // Fetch existing coupons when the page loads
  }

// Function to fetch coupons from the backend
  Future<void> _fetchCoupons() async {
    try {
      final response =
          await http.get(Uri.parse('http://$ipAddress/api/getAllCoupons'));
      if (response.statusCode == 200) {
        final List<dynamic> couponsData = jsonDecode(response.body);
        setState(() {
          _coupons.clear();
          _coupons.addAll(couponsData.map((coupon) {
            return Coupon(
              id: coupon['id'],
              code: coupon['code'],
              percentage:
                  double.tryParse(coupon['percentage'].toString()) ?? 0.0,
            );
          }).toList());
        });
      } else if (response.statusCode == 404) {
        // Handle no coupons case
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No coupons available')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to fetch coupons: ${response.body}')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _addCoupon() async {
    if (_codeController.text.isNotEmpty &&
        _percentageController.text.isNotEmpty) {
      try {
        final double? percentage = double.tryParse(_percentageController.text);
        if (percentage == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid percentage input')),
            );
          }
          return; // Exit if the percentage is invalid
        }

        final response = await http.post(
          Uri.parse('http://$ipAddress/api/addNewCoupon'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'code': _codeController.text,
            'percentage': percentage, // Use the parsed percentage
          }),
        );

        if (response.statusCode == 201) {
          final newCouponData = jsonDecode(response.body);

          if (newCouponData['coupon'] != null) {
            // Check if coupon data is returned
            final newCoupon = Coupon(
              id: newCouponData['coupon']['id'],
              code: newCouponData['coupon']['code'],
              percentage: newCouponData['coupon']['percentage'].toDouble(),
            );
            setState(() {
              _coupons.add(newCoupon);
              _codeController.clear();
              _percentageController.clear(); // Clear both inputs
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coupon added successfully')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to add coupon')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add coupon: ${response.body}')),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Code and percentage are required fields')),
        );
      }
    }
  }

  Future<void> _deleteCoupon(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://$ipAddress/api/deleteCoupon/$id'),
      );

      if (response.statusCode == 200) {
        // If the deletion is successful, update the UI
        if (mounted) {
          setState(() {
            _coupons.removeWhere((coupon) => coupon.id == id);
          });

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon deleted successfully')),
          );
        }
      } else {
        // Handle failure response from the backend
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete coupon')),
          );
        }
      }
    } catch (error) {
      // Catch and handle any errors
      print('Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred while deleting coupon')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Current coupons: $_coupons'); // Check what coupons are available before rendering

    return Scaffold(
      appBar: AppBar(
        flexibleSpace:
            const SnowLayer(), // Directly use SnowLayer without Container
        title: const Text('קופונים'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: 'קופון קוד...',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: TextField(
                controller: _percentageController,
                keyboardType:
                    TextInputType.number, // Set keyboard type to number
                decoration: InputDecoration(
                  hintText: 'הנחה באחוזים...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addCoupon,
                  ),
                ),
              ),
            ),
            // Check if there are any coupons
            _coupons.isEmpty
                ? Expanded(
                    child: Center(
                      child: Text(
                        'No coupons available',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _coupons.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: Key(_coupons[index].id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0.w),
                              child: const Icon(Icons.delete),
                            ),
                          ),
                          onDismissed: (direction) {
                            _deleteCoupon(_coupons[index].id);
                          },
                          child: ListTile(
                            title: Text(
                              _coupons[index].code,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              'הנחה: ${_coupons[index].percentage}%',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

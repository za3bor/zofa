import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Ensure you import this to use json.decode
import 'package:zofa_client/constant.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() {
    return _ProductDetailsScreenState();
  }
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<Map<String, dynamic>> productDetails;

  @override
  void initState() {
    super.initState();
    // Fetch product details when the screen is loaded
    productDetails = fetchProductDetails(widget.productId);
  }

  Future<Map<String, dynamic>> fetchProductDetails(int productId) async {
    final response = await http.get(
        Uri.parse('http://$ipAddress:3000/api/getProductDetails/$productId'));
    print(response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return product details as a Map
    } else {
      throw Exception('Failed to load product details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set the entire screen to RTL
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פרטי המוצר'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: productDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator()); // Loading indicator
            } else if (snapshot.hasError) {
              // Show error in a Snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('שגיאה: ${snapshot.error}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
              return const Center(
                child:
                    Text('שגיאה בטעינת פרטי המוצר.'), // Error message on screen
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text('לא נמצאו פרטי מוצר.'),
              ); // No product details available message
            }

            final productData = snapshot.data!;
            final categories = productData['categories'] as List<dynamic>;
            final allergies = productData['allergies'];
            final healthMarking = productData['healthMarking'] as List<dynamic>;
            final nutritionalValues = productData['nutritionalValues'] ?? {};
            final stock = productData['in_stock'];

            return SingleChildScrollView(
              // Wrap the entire body in SingleChildScrollView
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Section
                    Center(
                      child: Image.network(
                        'https://f003.backblazeb2.com/file/zofapic/${widget.productId}.jpeg',
                        height: 300,
                        width: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Display "Out of Stock" message if stock is 0 or less
                    if (stock == null || stock <= 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: Text(
                            'המוצר אזל מהמלאי',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Product Name
                    buildSectionHeader('שם מוצר'),
                    const SizedBox(height: 8),
                    Text(productData['name'] ?? 'לא נמצא שם המוצר',
                        style: const TextStyle(fontSize: 16)),

                    const SizedBox(height: 20),

                    // Product Data Section
                    buildSectionHeader('נתונים'),
                    const SizedBox(height: 8),
                    Text(productData['data'] ?? 'אין נתונים זמינים',
                        style: const TextStyle(fontSize: 14)),

                    const SizedBox(height: 20),

                    // Components Section
                    buildSectionHeader('רכיבים'),
                    const SizedBox(height: 8),
                    Text(productData['components'] ?? 'אין רכיבים זמינים',
                        style: const TextStyle(fontSize: 14)),

                    const SizedBox(height: 20),

                    // Additional Features Section
                    buildSectionHeader('מאפיינים נוספים'),
                    const SizedBox(height: 8),
                    Text(
                        productData['additional_features'] ??
                            'אין מאפיינים נוספים',
                        style: const TextStyle(fontSize: 14)),

                    const SizedBox(height: 20),

                    // Contains Section
                    buildSectionHeader('מכיל'),
                    const SizedBox(height: 8),
                    Text(productData['contain'] ?? 'אין פרטים על מכיל',
                        style: const TextStyle(fontSize: 14)),

                    const SizedBox(height: 20),

                    // May Contain Section
                    buildSectionHeader('עלול להכיל'),
                    const SizedBox(height: 8),
                    Text(
                        productData['may_contain'] ?? 'אין פרטים על עלול להכיל',
                        style: const TextStyle(fontSize: 14)),

                    const SizedBox(height: 20),

                    // Allergies Section
                    if (allergies != null && allergies.isNotEmpty) ...[
                      buildSectionHeader('אלרגנים'),
                      const SizedBox(height: 8),
                      Text(allergies, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 20),
                    ],
                    // Categories Section
                    buildSectionHeader('קטגוריות'),
                    const SizedBox(height: 8),
                    if (categories.isNotEmpty)
                      Text(categories.join(', '),
                          style: const TextStyle(
                              fontSize: 14)) // Display categories
                    else
                      const Text('אין קטגוריות זמינות.',
                          style: TextStyle(
                              fontSize:
                                  14)), // Message when no categories are found

                    const SizedBox(height: 20),

                    // Nutritional Values Header
                    buildSectionHeader(
                        'ערכים תזונתיים עבור 100 ${productData['is_beverage'] == 1 ? 'מ"ל' : 'גרם'}'),

                    const SizedBox(height: 8),

                    // Nutritional Values Table Section
                    nutritionalValues.isNotEmpty
                        ? Table(
                            border: TableBorder.all(color: Colors.grey),
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(3),
                            },
                            children: [
                              if (nutritionalValues['energy'] != null &&
                                  nutritionalValues['energy'] != '')
                                tableRow('קלוריות',
                                    '${nutritionalValues['energy']}'),
                              if (nutritionalValues['total_fats'] != null &&
                                  nutritionalValues['total_fats'] != '')
                                tableRow('סך השומנים מתוכן:',
                                    '${nutritionalValues['total_fats']}'),
                              if (nutritionalValues['saturated_fatty_acids'] !=
                                      null &&
                                  nutritionalValues['saturated_fatty_acids'] !=
                                      '')
                                tableRow('חומצות שומן רוויות',
                                    '${nutritionalValues['saturated_fatty_acids']}'),
                              if (nutritionalValues['trans_fatty_acids'] !=
                                      null &&
                                  nutritionalValues['trans_fatty_acids'] != '')
                                tableRow('חומצות שומן טראנס',
                                    '${nutritionalValues['trans_fatty_acids']}'),
                              if (nutritionalValues['cholesterol'] != null &&
                                  nutritionalValues['cholesterol'] != '')
                                tableRow('כולסטרול',
                                    '${nutritionalValues['cholesterol']}'),
                              if (nutritionalValues['sodium'] != null &&
                                  nutritionalValues['sodium'] != '')
                                tableRow(
                                    'נתרו', '${nutritionalValues['sodium']}'),
                              if (nutritionalValues['total_carbs'] != null &&
                                  nutritionalValues['total_carbs'] != '')
                                tableRow('סך הפחמימות מתוכן:',
                                    '${nutritionalValues['total_carbs']}'),
                              if (nutritionalValues['sugar'] != null &&
                                  nutritionalValues['sugar'] != '')
                                tableRow(
                                    'סוכרים', '${nutritionalValues['sugar']}'),
                              if (nutritionalValues['sugar_teaspoons'] !=
                                      null &&
                                  nutritionalValues['sugar_teaspoons'] != '')
                                tableRow('כפיות סוכר',
                                    '${nutritionalValues['sugar_teaspoons']}'),
                              if (nutritionalValues['rav_khaliem'] != null &&
                                  nutritionalValues['rav_khaliem'] != '')
                                tableRow('רב קהליים',
                                    '${nutritionalValues['rav_khaliem']}'),
                              if (nutritionalValues['dietary_fibers'] != null &&
                                  nutritionalValues['dietary_fibers'] != '')
                                tableRow('סיבים תזונתיים',
                                    '${nutritionalValues['dietary_fibers']}'),
                              if (nutritionalValues['proteins'] != null &&
                                  nutritionalValues['proteins'] != '')
                                tableRow('חלבונים',
                                    '${nutritionalValues['proteins']}'),
                              if (nutritionalValues['calcium'] != null &&
                                  nutritionalValues['calcium'] != '')
                                tableRow(
                                    'סידן', '${nutritionalValues['calcium']}'),
                              if (nutritionalValues['iron'] != null &&
                                  nutritionalValues['iron'] != '')
                                tableRow(
                                    'ברזל', '${nutritionalValues['iron']}'),
                            ],
                          )
                        : const Text('אין ערכים תזונתיים זמינים.',
                            style: TextStyle(fontSize: 14)),

                    const SizedBox(height: 20),

                    // Health Marking Section
                    if (healthMarking.isNotEmpty) ...[
                      buildSectionHeader('סימונים בריאותיים'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0, // Space between images
                        children: healthMarking.map((marking) {
                          return Image.asset(
                            'assets/$marking.png', // Image from local assets
                            height: 82,
                            width: 82,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Reusable method to build section header with underline and divider
  Widget buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(thickness: 1, color: Colors.grey),
      ],
    );
  }

  // Reusable method to create a row in the nutritional values table
  TableRow tableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
        ),
        body: Stack(
          children: [
            Container(
              color: const Color.fromARGB(
                  255, 222, 210, 206), // Set the background color
            ),
            FutureBuilder<Map<String, dynamic>>(
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
                    child: Text(
                        'שגיאה בטעינת פרטי המוצר.'), // Error message on screen
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('לא נמצאו פרטי מוצר.'),
                  ); // No product details available message
                }

                final productData = snapshot.data!;
                final categories = productData['categories'] as List<dynamic>;
                final allergies = productData['allergies'];
                final healthMarking =
                    productData['healthMarking'] as List<dynamic>;
                final nutritionalValues =
                    productData['nutritionalValues'] ?? {};
                final stock = productData['in_stock'];

                return SingleChildScrollView(
                  // Wrap the entire body in SingleChildScrollView
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 500,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors
                                  .transparent, // Make the container background transparent
                              borderRadius: BorderRadius.circular(
                                  10), // Optional: to round corners
                            ),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                const Color.fromARGB(255, 121, 85, 72).withOpacity(
                                    0.25), // Set the desired color with opacity
                                BlendMode.darken,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: widget.productId >
                                        0 // Check if the product ID is a valid integer
                                    ? Hero(
                                        tag:
                                            'imageHero-${widget.productId}', // Unique tag for Hero animation
                                        child: Image.network(
                                          'https://f003.backblazeb2.com/file/zofapic/${widget.productId}.jpeg',
                                          height: 300,
                                          width: 300,
                                          fit: BoxFit.cover,
                                          errorBuilder: (BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace) {
                                            return Image.asset(
                                              'assets/noimage.jpg', // Fallback image if error loading
                                              fit: BoxFit.cover,
                                              height: 300,
                                              width: 300,
                                            );
                                          },
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/noimage.jpg', // Fallback image if productId is invalid
                                        fit: BoxFit.cover,
                                        height: 300,
                                        width: 300,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (stock==0) ...[
                          const Text(
                            'המוצר אזל מהמלאי',
                            style: TextStyle(color: Colors.red),
                          )
                        ],
                        // Product Name
                        if (productData['name'] != null &&
                            productData['name'].isNotEmpty) ...[
                          buildSectionHeader('שם מוצר'),
                          const SizedBox(height: 8),
                          Text(productData['name'] ?? 'לא נמצא שם המוצר',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
                        ],

                        // Product Data Section
                        if (productData['data'] != null &&
                            productData['data'].isNotEmpty) ...[
                          buildSectionHeader('נתונים'),
                          const SizedBox(height: 8),
                          Text(productData['data'] ?? 'אין נתונים זמינים',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                        ],

                        // Components Section
                        if (productData['components'] != null &&
                            productData['components'].isNotEmpty) ...[
                          buildSectionHeader('רכיבים'),
                          const SizedBox(height: 8),
                          Text(productData['components'] ?? 'אין רכיבים זמינים',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                        ],

                        // Additional Features Section
                        if (productData['additional_features'] != null &&
                            productData['additional_features'].isNotEmpty) ...[
                          buildSectionHeader('מאפיינים נוספים'),
                          const SizedBox(height: 8),
                          Text(
                              productData['additional_features'] ??
                                  'אין מאפיינים נוספים',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                        ],

                        // Contains Section
                        if (productData['contain'] != null &&
                            productData['contain'].isNotEmpty) ...[
                          buildSectionHeader('מכיל'),
                          const SizedBox(height: 8),
                          Text(productData['contain'] ?? 'אין פרטים על מכיל',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                        ],

                        // May Contain Section
                        if (productData['may_contain'] != null &&
                            productData['may_contain'].isNotEmpty) ...[
                          buildSectionHeader('עלול להכיל'),
                          const SizedBox(height: 8),
                          Text(
                              productData['may_contain'] ??
                                  'אין פרטים על עלול להכיל',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                        ],

                        // Allergies Section
                        if (allergies != null && allergies.isNotEmpty) ...[
                          buildSectionHeader('אלרגנים'),
                          const SizedBox(height: 8),
                          Text(allergies, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                        ],

                        // Categories Section
                        if (categories.isNotEmpty) ...[
                          buildSectionHeader('קטגוריות'),
                          const SizedBox(height: 8),
                          Text(categories.join(', '),
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                        ],

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
                          const SizedBox(height: 20),
                        ],

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
                                  if (nutritionalValues[
                                              'saturated_fatty_acids'] !=
                                          null &&
                                      nutritionalValues[
                                              'saturated_fatty_acids'] !=
                                          '')
                                    tableRow('חומצות שומן רוויות',
                                        '${nutritionalValues['saturated_fatty_acids']}'),
                                  if (nutritionalValues['trans_fatty_acids'] !=
                                          null &&
                                      nutritionalValues['trans_fatty_acids'] !=
                                          '')
                                    tableRow('חומצות שומן טראנס',
                                        '${nutritionalValues['trans_fatty_acids']}'),
                                  if (nutritionalValues['cholesterol'] !=
                                          null &&
                                      nutritionalValues['cholesterol'] != '')
                                    tableRow('כולסטרול',
                                        '${nutritionalValues['cholesterol']}'),
                                  if (nutritionalValues['sodium'] != null &&
                                      nutritionalValues['sodium'] != '')
                                    tableRow('נתרו',
                                        '${nutritionalValues['sodium']}'),
                                  if (nutritionalValues['total_carbs'] !=
                                          null &&
                                      nutritionalValues['total_carbs'] != '')
                                    tableRow('סך הפחמימות מתוכן:',
                                        '${nutritionalValues['total_carbs']}'),
                                  if (nutritionalValues['sugar'] != null &&
                                      nutritionalValues['sugar'] != '')
                                    tableRow('סוכרים',
                                        '${nutritionalValues['sugar']}'),
                                  if (nutritionalValues['sugar_teaspoons'] !=
                                          null &&
                                      nutritionalValues['sugar_teaspoons'] !=
                                          '')
                                    tableRow('כפיות סוכר',
                                        '${nutritionalValues['sugar_teaspoons']}'),
                                  if (nutritionalValues['rav_khaliem'] !=
                                          null &&
                                      nutritionalValues['rav_khaliem'] != '')
                                    tableRow('רב קהליים',
                                        '${nutritionalValues['rav_khaliem']}'),
                                  if (nutritionalValues['dietary_fibers'] !=
                                          null &&
                                      nutritionalValues['dietary_fibers'] != '')
                                    tableRow('סיבים תזונתיים',
                                        '${nutritionalValues['dietary_fibers']}'),
                                  if (nutritionalValues['proteins'] != null &&
                                      nutritionalValues['proteins'] != '')
                                    tableRow('חלבונים',
                                        '${nutritionalValues['proteins']}'),
                                  if (nutritionalValues['calcium'] != null &&
                                      nutritionalValues['calcium'] != '')
                                    tableRow('סידן',
                                        '${nutritionalValues['calcium']}'),
                                  if (nutritionalValues['iron'] != null &&
                                      nutritionalValues['iron'] != '')
                                    tableRow(
                                        'ברזל', '${nutritionalValues['iron']}'),
                                ],
                              )
                            : const Text('אין ערכים תזונתיים זמינים.',
                                style: TextStyle(fontSize: 14)),

                        // Disclaimer Text
                        const SizedBox(height: 20),
                        const Divider(
                          color: Colors.black,
                          thickness: 1.5,
                        ),
                        const Text(
                          'אין להסתמך על הפירוט המופיע באפליקציה על מרכיבי המוצר, יתכנו טעויות או אי התאמות במידע, הנתונים המדויקים מופיעים על גבי המוצר. יש לבדוק שוב את הנתונים על גבי אריזת המוצר לפני השימוש.',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
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

  // Reusable method to build section header with underline and divider
  Widget buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(thickness: 1, color: Colors.black),
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

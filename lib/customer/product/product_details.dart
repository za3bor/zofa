import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zofa/customer/sales/sale_details_screen.dart';

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
  List<int> saleIds = [];

  @override
  void initState() {
    super.initState();
    // Fetch product details when the screen is loaded
    productDetails = fetchProductDetails(widget.productId);
    // Fetch sale IDs for this product
    fetchSaleIdsForProduct(widget.productId).then((ids) {
      setState(() {
        saleIds = ids;
      });
    });
  }

  Future<Map<String, dynamic>> fetchProductDetails(int productId) async {
    final response = await http.get(
      Uri.parse('http://$ipAddress/api/getProductDetails/$productId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return product details as a Map
    } else {
      throw Exception('Failed to load product details');
    }
  }

  Future<List<int>> fetchSaleIdsForProduct(int productId) async {
    final uri = Uri.parse('http://$ipAddress/api/salesProduct/$productId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['saleIds'] is List) {
          return List<int>.from(data['saleIds']);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to fetch sale IDs: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching sale IDs: $e')));
      }
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'אודות המוצר'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Container(
              color: const Color.fromARGB(
                255,
                222,
                210,
                206,
              ), // Set the background color
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: productDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  return const Center(child: Text('שגיאה בטעינת פרטי המוצר.'));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('לא נמצאו פרטי מוצר.'));
                }

                final productData = snapshot.data!;
                final categories = productData['categories'] as List<dynamic>;
                final allergies = productData['allergies'];
                final healthMarking =
                    productData['healthMarking'] as List<dynamic>;
                final nutritionalValues =
                    productData['nutritionalValues'] ?? {};
                final customnutritionalValues =
                    productData['customnutritionalValues'] ?? {};
                final stock = productData['in_stock'];
                final isSeeds = productData['is_seeds'];
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image Section
                        Center(
                          child: Container(
                            width: 500.h,
                            height: 300.w,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child:
                                  widget.productId > 0
                                      ? Hero(
                                        tag: 'imageHero-${widget.productId}',
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            const Color.fromARGB(
                                              255,
                                              121,
                                              85,
                                              72,
                                            ).withValues(alpha: 0.25),
                                            BlendMode.darken,
                                          ),
                                          child: Image.network(
                                            'https://d1qq705dywrog2.cloudfront.net/images/${widget.productId}.jpeg',
                                            height: 300.h,
                                            width: 300.w,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace,
                                            ) {
                                              return Image.asset(
                                                'assets/noimage.jpg',
                                                fit: BoxFit.cover,
                                                height: 300.h,
                                                width: 300.w,
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                      : Image.asset(
                                        'assets/noimage.jpg',
                                        fit: BoxFit.cover,
                                        height: 300.h,
                                        width: 300.w,
                                      ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Stock information
                        // Stock info
                        if (stock == 0) ...[
                          Text(
                            'המוצר אזל מהמלאי',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],
                        if (saleIds.isNotEmpty) ...[
                          Text(
                            'מוצר זה נמצא במבצע!',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Add buttons for each sale ID
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 10.h,
                            children:
                                saleIds.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final saleId = entry.value;
                                  return ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => SaleDetailsScreen(
                                                saleId: saleId,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.local_offer),
                                    label: Text('לצפייה במבצע ${index + 1}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown.shade200,
                                      foregroundColor: Colors.black,
                                      textStyle: TextStyle(fontSize: 14.sp),
                                    ),
                                  );
                                }).toList(),
                          ),

                          SizedBox(height: 8.h),
                        ],

                        SizedBox(height: 8.h),
                        // Use helper for standard sections
                        buildTextSection(
                          value: productData['name'],
                          label: 'שם מוצר',
                          fallback: 'לא נמצא שם המוצר',
                        ),

                        buildTextSection(
                          value: productData['price'],
                          label: (isSeeds == 1) ? 'מחיר לק״ג' : 'מחיר',
                          fallback: 'לא נמצא מחיר המוצר',
                        ),

                        buildTextSection(
                          value: productData['data'],
                          label: 'נתונים',
                          fallback: 'אין נתונים זמינים',
                        ),

                        buildTextSection(
                          value: productData['components'],
                          label: 'רכיבים',
                          fallback: 'אין רכיבים זמינים',
                        ),

                        buildTextSection(
                          value: productData['additional_features'],
                          label: 'מאפיינים נוספים',
                          fallback: 'אין מאפיינים נוספים',
                        ),

                        buildTextSection(
                          value: productData['contain'],
                          label: 'מכיל',
                          fallback: 'אין פרטים על מכיל',
                        ),

                        buildTextSection(
                          value: productData['may_contain'],
                          label: 'עלול להכיל',
                          fallback: 'אין פרטים על עלול להכיל',
                        ),

                        buildTextSection(value: allergies, label: 'אלרגיות'),

                        if (categories.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildSectionHeader('קטגוריות'),
                              SizedBox(height: 8.h),
                              Text(categories.join(', ')),
                              SizedBox(height: 20.h),
                            ],
                          ),

                        if (healthMarking.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildSectionHeader('סימונים בריאותיים'),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.0,
                                runSpacing:
                                    8.0, // vertical spacing between rows

                                children:
                                    healthMarking.map((marking) {
                                      return Image.asset(
                                        'assets/$marking.png',
                                        height: 82,
                                        width: 82,
                                      );
                                    }).toList(),
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),

                        // Standard Nutritional Values
                        buildSectionHeader(
                          'ערכים תזונתיים עבור 100 ${productData['is_beverage'] == 1 ? 'מ"ל' : 'גרם'}',
                        ),
                        SizedBox(height: 8.h),
                        buildNutritionalTable(nutritionalValues),

                        // Custom Nutritional Values
                        if (customnutritionalValues.isNotEmpty) ...[
                          SizedBox(height: 20.h),
                          buildSectionHeader(
                            customnutritionalValues['fieldname']?.toString() ??
                                'כותרת חסרה',
                          ),
                          SizedBox(height: 8.h),
                          buildNutritionalTable(customnutritionalValues),
                        ],

                        SizedBox(height: 20.h),

                        Divider(color: Colors.black, thickness: 2.h),
                        Text(
                          'אין להסתמך על הפירוט המופיע באפליקציה על מרכיבי המוצר, יתכנו טעויות או אי התאמות במידע, הנתונים המדויקים מופיעים על גבי המוצר. יש לבדוק שוב את הנתונים על גבי אריזת המוצר לפני השימוש.',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12.h),
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
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        Divider(thickness: 1.h, color: Colors.black),
      ],
    );
  }

  // Reusable method to create a row in the nutritional values table
  TableRow tableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0.w),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0.w),
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  /// List of nutritional field labels and keys
  final List<Map<String, String>> nutritionalFields = [
    {'label': 'קלוריות', 'key': 'energy'},
    {'label': 'סך השומנים מתוכן:', 'key': 'total_fats'},
    {'label': 'חומצות שומן רוויות', 'key': 'saturated_fatty_acids'},
    {'label': 'חומצות שומן טראנס', 'key': 'trans_fatty_acids'},
    {'label': 'כולסטרול', 'key': 'cholesterol'},
    {'label': 'נתרו', 'key': 'sodium'},
    {'label': 'סך הפחמימות מתוכן:', 'key': 'total_carbs'},
    {'label': 'סוכרים', 'key': 'sugar'},
    {'label': 'כפיות סוכר', 'key': 'sugar_teaspoons'},
    {'label': 'רב קהליים', 'key': 'rav_khaliem'},
    {'label': 'סיבים תזונתיים', 'key': 'dietary_fibers'},
    {'label': 'חלבונים', 'key': 'proteins'},
    {'label': 'סידן', 'key': 'calcium'},
    {'label': 'ברזל', 'key': 'iron'},
    {'label': 'אשלגן', 'key': 'potassium'},
    {'label': 'מגנזיום', 'key': 'magnesium'},
    {'label': 'חומצה לאורית', 'key': 'lauricAcid'},
    {'label': 'אבץ', 'key': 'zinc'},
  ];

  /// Function to build nutritional values table from map
  Widget buildNutritionalTable(Map values) {
    final rows =
        nutritionalFields
            .where(
              (item) =>
                  values[item['key']] != null && values[item['key']] != '',
            )
            .map(
              (item) =>
                  tableRow(item['label']!, values[item['key']!].toString()),
            )
            .toList();

    if (rows.isEmpty) {
      return const Text('אין ערכים תזונתיים זמינים.');
    }

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
      children: rows,
    );
  }

  Widget buildTextSection({
    required String? value,
    required String label,
    String? fallback,
  }) {
    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(label),
        SizedBox(height: 8.h),
        Text(value),
        SizedBox(height: 20.h),
      ],
    );
  }
}

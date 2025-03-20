import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final response = await http
        .get(Uri.parse('http://$ipAddress/api/getProductDetails/$productId'));
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return product details as a Map
    } else {
      throw Exception('Failed to load product details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'פרטי המוצר',
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Container(
              color: const Color.fromARGB(
                  255, 222, 210, 206), // Set the background color
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
                  return const Center(
                    child: Text('שגיאה בטעינת פרטי המוצר.'),
                  );
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
                final stock = productData['in_stock'];

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
                              child: widget.productId > 0
                                  ? Hero(
                                      tag: 'imageHero-${widget.productId}',
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          const Color.fromARGB(255, 121, 85, 72)
                                              .withValues(alpha: 0.25),
                                          BlendMode.darken,
                                        ),
                                        child: Image.network(
                                          'https://d1qq705dywrog2.cloudfront.net/images/${widget.productId}.jpeg',
                                          height: 300.h,
                                          width: 300.w,
                                          fit: BoxFit.cover,
                                          errorBuilder: (BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace) {
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
                        if (stock == 0) ...[
                          Text(
                            'המוצר אזל מהמלאי',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 8.h),
                        ],

                        // Product Data Sections
                        if (productData['name'] != null &&
                            productData['name'].isNotEmpty) ...[
                          buildSectionHeader('שם מוצר'),
                          SizedBox(height: 8.h),
                          Text(
                            productData['name'] ?? 'לא נמצא שם המוצר',
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Product Data Sections
                        if (productData['price'] != null &&
                            productData['price'].isNotEmpty) ...[
                          buildSectionHeader('מחיר'),
                          SizedBox(height: 8.h),
                          Text(
                            productData['price'] ?? 'לא נמצא מחיר המוצר',
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Product Data Section
                        if (productData['data'] != null &&
                            productData['data'].isNotEmpty) ...[
                          buildSectionHeader('נתונים'),
                          SizedBox(height: 8.h),
                          Text(
                            productData['data'] ?? 'אין נתונים זמינים',
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Components Section
                        if (productData['components'] != null &&
                            productData['components'].isNotEmpty) ...[
                          buildSectionHeader('רכיבים'),
                          SizedBox(height: 8.h),
                          Text(
                            productData['components'] ?? 'אין רכיבים זמינים',
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Additional Features Section
                        if (productData['additional_features'] != null &&
                            productData['additional_features'].isNotEmpty) ...[
                          buildSectionHeader('מאפיינים נוספים'),
                          SizedBox(height: 8.h),
                          Text(
                            productData['additional_features'] ??
                                'אין מאפיינים נוספים',
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Contains Section
                        if (productData['contain'] != null &&
                            productData['contain'].isNotEmpty) ...[
                          buildSectionHeader('מכיל'),
                          SizedBox(height: 8.h),
                          Text(
                            productData['contain'] ?? 'אין פרטים על מכיל',
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // May Contain Section
                        if (productData['may_contain'] != null &&
                            productData['may_contain'].isNotEmpty) ...[
                          buildSectionHeader('עלול להכיל'),
                          SizedBox(height: 8.h),
                          Text(
                            productData['may_contain'] ??
                                'אין פרטים על עלול להכיל',
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Allergies Section
                        if (allergies != null && allergies.isNotEmpty) ...[
                          buildSectionHeader('אלרגנים'),
                          SizedBox(height: 8.h),
                          Text(
                            allergies,
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Categories Section
                        if (categories.isNotEmpty) ...[
                          buildSectionHeader('קטגוריות'),
                          SizedBox(height: 8.h),
                          Text(
                            categories.join(', '),
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Health Marking Section
                        if (healthMarking.isNotEmpty) ...[
                          buildSectionHeader('סימונים בריאותיים'),
                          SizedBox(height: 8.h),
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
                          SizedBox(height: 20.h),
                        ],

                        // Nutritional Values Header
                        buildSectionHeader(
                            'ערכים תזונתיים עבור 100 ${productData['is_beverage'] == 1 ? 'מ"ל' : 'גרם'}'),

                        SizedBox(height: 8.h),

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
                            : const Text(
                                'אין ערכים תזונתיים זמינים.',
                              ),

                        // Disclaimer Text
                        SizedBox(height: 20.h),
                        Divider(
                          color: Colors.black,
                          thickness: 2.h,
                        ),
                        Text(
                          'אין להסתמך על הפירוט המופיע באפליקציה על מרכיבי המוצר, יתכנו טעויות או אי התאמות במידע, הנתונים המדויקים מופיעים על גבי המוצר. יש לבדוק שוב את הנתונים על גבי אריזת המוצר לפני השימוש.',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                fontSize: 17.sp,
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
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0.w),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

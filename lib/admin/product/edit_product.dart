import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zofa/models/category.dart';
import 'package:zofa/models/health_marking.dart';
import 'package:zofa/widgets/editable_custom_nutritional_table.dart';
import 'package:zofa/widgets/editable_nutritional_table.dart';
import 'package:zofa/widgets/editable_textfield.dart';

class EditProductScreen extends StatefulWidget {
  final int productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() {
    return _EditProductScreenState();
  }
}

class _EditProductScreenState extends State<EditProductScreen> {
  late Future<Map<String, dynamic>> productDetails;
  // Add these fields:
  List<Category> _categories = []; // List to store fetched categories
  final Map<int, bool> _categorySelections =
      {}; // Store selections for each category
  List<HealthMarking> _healthMarking =
      []; // List to store fetched health markings
  final Map<int, bool> _healthMarkingSelections =
      {}; // Store selections for each health marking
  Set<String> selectedHealthMarking = {}; // health marking assigned to product
  Map<String, TextEditingController> nutritionalControllers = {};

  /// state for your boolean flags
  Map<String, bool> booleanValues = {'of_which_f': false, 'of_which_c': false};
  Map<String, TextEditingController> customNutritionalControllers = {};
  // Initialize controllers for text fields
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController allergiesController;
  late TextEditingController dataController;
  late TextEditingController componentsController;
  late TextEditingController additionalFeaturesController;
  late TextEditingController containController;
  late TextEditingController mayContainController;
  bool _categoriesInitialized = false;
  bool _healthMarkingInitialized = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    // Fetch product details when the screen is loaded
    productDetails = fetchProductDetails(widget.productId);
    fetchAllCategories();
    fetchAllHealthMarking();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    allergiesController.dispose();
    dataController.dispose();
    componentsController.dispose();
    additionalFeaturesController.dispose();
    containController.dispose();
    mayContainController.dispose();
    for (var c in nutritionalControllers.values) {
      c.dispose();
    }
    for (var c in customNutritionalControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> fetchAllCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/getAllCategories'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _categories =
              jsonData.map((item) {
                return Category(
                  id: item['id'], // Assuming 'id' is a key in the response
                  name:
                      item['name'], // Assuming 'name' is a key in the response
                );
              }).toList();

          // Initialize the category selections
          for (var category in _categories) {
            _categorySelections[category.id] = false; // Default to unselected
          }
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching categories: $e')),
        );
      }
    }
  }

  Future<void> fetchAllHealthMarking() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/getAllHealthMarking'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _healthMarking =
              jsonData.map((item) {
                return HealthMarking(
                  id: item['id'], // Assuming 'id' is a key in the response
                  name:
                      item['name'], // Assuming 'name' is a key in the response
                );
              }).toList();

          // Initialize the health marking selections
          for (var healthMark in _healthMarking) {
            _healthMarkingSelections[healthMark.id] =
                false; // Default to unselected
          }
        });
      } else {
        throw Exception('Failed to load health markings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching health markings: $e')),
        );
      }
    }
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

  // Method to save the selected categories
  Future<void> _saveCategoryChanges() async {
    try {
      // Gather selected category IDs
      List<int> selectedCategoryIds =
          _categorySelections.entries
              .where((entry) => entry.value) // Only selected categories
              .map((entry) => entry.key) // Get the category IDs
              .toList();

      // If there are selected categories, send them to the backend or handle accordingly
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/saveProductCategories'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': widget.productId,
          'categories': selectedCategoryIds,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categories saved successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save categories')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving categories: $e')));
      }
    }
  }

  // Method to save the selected health markings
  Future<void> _saveHealthMarkingsChanges() async {
    try {
      // Gather selected health markings IDs
      List<int> selectedHealthMarkingsIds =
          _healthMarkingSelections.entries
              .where((entry) => entry.value) // Only selected health markings
              .map((entry) => entry.key) // Get the health marking IDs
              .toList();

      // If there are selected health markings, send them to the backend or handle accordingly
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/saveProductHealthMarking'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': widget.productId,
          'healthMarking': selectedHealthMarkingsIds,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health markings saved successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save Health markings')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Health markings: $e')),
        );
      }
    }
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
                if (snapshot.hasData && !_categoriesInitialized) {
                  // One-time, synchronous assignment—NO setState here!
                  final names = List<String>.from(
                    snapshot.data!['categories'] ?? [],
                  );
                  for (var cat in _categories) {
                    _categorySelections[cat.id] = names.contains(cat.name);
                  }
                  _categoriesInitialized = true;
                }
                if (snapshot.hasData && !_healthMarkingInitialized) {
                  // One-time, synchronous assignment—NO setState here!
                  final marksNames = List<String>.from(
                    snapshot.data!['healthMarking'] ?? [],
                  );
                  for (var mark in _healthMarking) {
                    _healthMarkingSelections[mark.id] = marksNames.contains(
                      mark.name,
                    );
                  }
                  _healthMarkingInitialized = true;
                }
                if (snapshot.hasData && !_controllersInitialized) {
                  final productData = snapshot.data!;
                  final allergies = productData['allergies'];

                  // Initialize text controllers for editable fields:
                  nameController = TextEditingController(
                    text: productData['name'] ?? '',
                  );
                  priceController = TextEditingController(
                    text: productData['price']?.toString() ?? '',
                  );
                  allergiesController = TextEditingController(
                    text: allergies ?? '',
                  );
                  dataController = TextEditingController(
                    text: productData['data'] ?? '',
                  );
                  componentsController = TextEditingController(
                    text: productData['components'] ?? '',
                  );
                  additionalFeaturesController = TextEditingController(
                    text: productData['additional_features'] ?? '',
                  );
                  containController = TextEditingController(
                    text: productData['contain'] ?? '',
                  );
                  mayContainController = TextEditingController(
                    text: productData['may_contain'] ?? '',
                  );
                    final nutritionalValues = productData['nutritionalValues'] ?? {};
  for (var field in nutritionalFields) {
    final key  = field['key']!;
    final type = field['type']!;
    if (type != 'bool') {
      final initVal = nutritionalValues[key]?.toString() ?? '';
      nutritionalControllers[key] = TextEditingController(text: initVal);
    } else {
      booleanValues[key] = (nutritionalValues[key] == 1 || nutritionalValues[key] == true);
    }
  }

  // —— NEW: initialize custom nutritional controllers ONCE ——
  final customValues = productData['customnutritionalValues'] ?? {};
  customValues.forEach((key, value) {
    customNutritionalControllers[key] = TextEditingController(text: value.toString());
  });
                  _controllersInitialized = true;
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

                final nutritionalValues =
                    productData['nutritionalValues'] ?? {};
                final customnutritionalValues =
                    productData['customnutritionalValues'] ?? {};
                final stock = productData['in_stock'];
                // Initialize controllers for standard nutritional values

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

                        EditableTextField(
                          label: 'שם מוצר',
                          controller: nameController,
                          barcode: widget.productId,
                          fieldName: 'name',
                        ),
                        EditableTextField(
                          label: 'מחיר',
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          barcode: widget.productId,
                          fieldName: 'price',
                        ),
                        EditableTextField(
                          label: 'נתונים',
                          controller: dataController,
                          maxLines: 2,
                          barcode: widget.productId,
                          fieldName: 'data',
                        ),
                        EditableTextField(
                          label: 'רכיבים',
                          controller: componentsController,
                          maxLines: 3,
                          barcode: widget.productId,
                          fieldName: 'components',
                        ),
                        EditableTextField(
                          label: 'מאפיינים נוספים',
                          controller: additionalFeaturesController,
                          maxLines: 2,
                          barcode: widget.productId,
                          fieldName: 'additional_features',
                        ),
                        EditableTextField(
                          label: 'מכיל',
                          controller: containController,
                          maxLines: 2,
                          barcode: widget.productId,
                          fieldName: 'contain',
                        ),
                        EditableTextField(
                          label: 'עלול להכיל',
                          controller: mayContainController,
                          maxLines: 2,
                          barcode: widget.productId,
                          fieldName: 'may_contain',
                        ),
                        EditableTextField(
                          label: 'אלרגיות',
                          controller: allergiesController,
                          maxLines: 2,
                          barcode: widget.productId,
                          fieldName: 'allergies',
                        ),
                        // Replace your categories section with checkbox list:
                        SizedBox(height: 20.h),
                        buildSectionHeader('קטגוריות'),
                        Wrap(
                          children:
                              _categories.map((category) {
                                return CheckboxListTile(
                                  title: Text(
                                    category.name,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  value: _categorySelections[category.id],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _categorySelections[category.id] =
                                          value ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 20.h),

                        // Save Categories Button
                        ElevatedButton(
                          onPressed: _saveCategoryChanges,
                          child: const Text('שמור קטגוריות'),
                        ),
                        SizedBox(height: 20.h),

                        buildSectionHeader('סימנים בריאותיים'),
                        SizedBox(height: 8.h),
                        Wrap(
                          children:
                              _healthMarking.map((healthMark) {
                                return CheckboxListTile(
                                  title: Text(
                                    healthMark.name,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  value:
                                      _healthMarkingSelections[healthMark.id],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _healthMarkingSelections[healthMark.id] =
                                          value ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 10.h),

                        ElevatedButton(
                          onPressed: _saveHealthMarkingsChanges,
                          child: const Text('שמור סימנים בריאותיים'),
                        ),
                        SizedBox(height: 20.h),

                        // Standard Nutritional Values
                        buildSectionHeader(
                          'ערכים תזונתיים עבור 100 ${productData['is_beverage'] == 1 ? 'מ"ל' : 'גרם'}',
                        ),
                        SizedBox(height: 8.h),
                        EditableNutritionalTable(
                          values: nutritionalValues,
                          controllers: nutritionalControllers,
                          booleanValues: booleanValues, // new!

                          nutritionalFields: nutritionalFields,
                          barcode: widget.productId,
                        ),

                        // Custom Nutritional Values
                        if (customnutritionalValues.isNotEmpty) ...[
                          SizedBox(height: 25.h),
                          buildSectionHeader(
                            customnutritionalValues['fieldname']?.toString() ??
                                'כותרת חסרה',
                          ),
                          SizedBox(height: 8.h),
                          EditableCustomNutritionalTable(
                            values: customnutritionalValues,
                            controllers: customNutritionalControllers,
                            nutritionalFields: customnutritionalFields,
                            barcode: widget.productId,
                          ),
                        ],

                        SizedBox(height: 20.h),
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

  // List of nutritional field labels and keys
  final List<Map<String, String>> nutritionalFields = [
    {'label': 'קלוריות', 'key': 'energy', 'type': 'String'},
    {'label': 'סך השומנים מתוכן:', 'key': 'total_fats', 'type': 'String'},
    {'label': 'מתוך השומנים:', 'key': 'of_which_f', 'type': 'bool'},
    {
      'label': 'חומצות שומן רוויות',
      'key': 'saturated_fatty_acids',
      'type': 'String',
    },
    {
      'label': 'חומצות שומן טראנס',
      'key': 'trans_fatty_acids',
      'type': 'String',
    },
    {'label': 'כולסטרול', 'key': 'cholesterol', 'type': 'String'},
    {'label': 'נתרו', 'key': 'sodium', 'type': 'String'},
    {'label': 'סך הפחמימות מתוכן:', 'key': 'total_carbs', 'type': 'String'},
    {'label': 'מתוך הפחמימות:', 'key': 'of_which_c', 'type': 'bool'},
    {'label': 'סוכרים', 'key': 'sugar', 'type': 'String'},
    {'label': 'כפיות סוכר', 'key': 'sugar_teaspoons', 'type': 'String'},
    {'label': 'רב קהליים', 'key': 'rav_khaliem', 'type': 'String'},
    {'label': 'סיבים תזונתיים', 'key': 'dietary_fibers', 'type': 'String'},
    {'label': 'חלבונים', 'key': 'proteins', 'type': 'String'},
    {'label': 'סידן', 'key': 'calcium', 'type': 'String'},
    {'label': 'ברזל', 'key': 'iron', 'type': 'String'},
    {'label': 'אשלגן', 'key': 'potassium', 'type': 'String'},
    {'label': 'מגנזיום', 'key': 'magnesium', 'type': 'String'},
    {'label': 'חומצה לאורית', 'key': 'lauricAcid', 'type': 'String'},
    {'label': 'אבץ', 'key': 'zinc', 'type': 'String'},
  ];

  // List of nutritional field labels and keys
  final List<Map<String, String>> customnutritionalFields = [
    {'label': 'שם טבלה', 'key': 'fieldname'},
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
}

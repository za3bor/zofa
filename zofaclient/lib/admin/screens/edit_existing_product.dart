import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/models/category.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditExistingProductScreen extends StatefulWidget {
  const EditExistingProductScreen({super.key});

  @override
  State<EditExistingProductScreen> createState() {
    return _TextFieldDropdownPageState();
  }
}

class _TextFieldDropdownPageState extends State<EditExistingProductScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _newWordController = TextEditingController();
  String? _selectedItem; // Store the selected dropdown item

  // Mapping Hebrew fields to their English counterparts
  final Map<String, String> _fieldMap = {
    'שם מוצר': 'name',
    'מידע': 'data',
    'מרכיבים': 'components',
    'מאפיינים נוספים': 'additional_features',
    'מכיל': 'contain',
    'עלול להכיל': 'may_contain',
    'אלרגיות': 'allergies',
    'מחיר': 'price',
  };

  final List<String> _dropdownItems = [
    'שם מוצר',
    'מידע',
    'מרכיבים',
    'מאפיינים נוספים',
    'מכיל',
    'עלול להכיל',
    'אלרגיות',
    'מחיר'
  ];

  List<Category> _categories = []; // List to store fetched categories
  final Map<int, bool> _categorySelections = {}; // Store selections for each category

  Future<void> _fetchCategories() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress:3000/api/getAllCategories'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _categories = jsonData.map((item) {
            return Category(
              id: item['id'], // Assuming 'id' is a key in the response
              name: item['name'], // Assuming 'name' is a key in the response
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
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchProductCategories() async {
    try {
      final barcode = _barcodeController.text; // Get the barcode from input
      final response = await http.get(Uri.parse(
          'http://$ipAddress:3000/api/getProductCategories/$barcode'));

      if (response.statusCode == 200) {
        final List<dynamic> productCategories = jsonDecode(response.body);
        print(
            'Product Categories: $productCategories'); // Debug print for response

        setState(() {
          // Loop through each category and check if it matches with _categorySelections
          for (var categoryName in productCategories) {
            // Find the category by matching the 'name' (not the 'id') with category names
            var matchingCategory = _categories.firstWhere(
              (cat) => cat.name == categoryName,
              orElse: () => Category(
                  id: -1, name: categoryName), // Default value if not found
            );

            // If a matching category is found (id != -1), mark it as selected
            if (matchingCategory.id != -1) {
              _categorySelections[matchingCategory.id] = true;
            }
          }
        });
      } else {
        if (mounted) {
          // If no categories are found for the barcode, show a message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Barcode not found or no categories assigned')),
          );
        }
      }
    } catch (e) {
      print('Error fetching product categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching product categories')),
        );
      }
    }
  }

  Future<void> _updateProduct() async {
    final String barcode = _barcodeController.text;
    final String newWord = _newWordController.text;
    final String? fieldInEnglish = _fieldMap[_selectedItem ?? ''];

    if (fieldInEnglish != null && newWord.isNotEmpty && barcode.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('http://$ipAddress:3000/api/updateProductField'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'id': barcode, // Barcode is being used as the product ID
            'field': fieldInEnglish,
            'newValue': newWord,
          }),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            // Handle success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product updated successfully')),
            );
          }
          _barcodeController.clear();
          _newWordController.clear();
        } else {
          if (mounted) {
            // Handle failure
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update product')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Unable to update product')),
          );
        }
      }
    } else {
      // Show error if field or text is missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

// Method to save the selected categories
  Future<void> _saveCategoryChanges() async {
    try {
      // Gather selected category IDs
      List<int> selectedCategoryIds = _categorySelections.entries
          .where((entry) => entry.value) // Only selected categories
          .map((entry) => entry.key) // Get the category IDs
          .toList();

      // If there are selected categories, send them to the backend or handle accordingly
      if (selectedCategoryIds.isNotEmpty) {
        final barcode = _barcodeController.text;
        final response = await http.post(
          Uri.parse('http://$ipAddress:3000/api/saveProductCategories'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'barcode': barcode,
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one category')),
        );
      }
    } catch (e) {
      print('Error saving categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving categories')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when the page is initialized
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _newWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('עריכת מוצר'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barcode TextField (Numbers only)
                const Text(
                  'הכנס ברקוד:',
                ),
                TextField(
                  controller: _barcodeController,
                  keyboardType: TextInputType.number, // Restrict to numbers
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'ברקוד',
                  ),
                ),
                SizedBox(height: 20.h),
        
                // Button to check and set categories
                ElevatedButton(
                  onPressed: _fetchProductCategories,
                  child: const Text('הפעל'),
                ),
                SizedBox(height: 20.h),
                // New Word TextField
                const Text(
                  'הכנס את הערך החדש:',
                ),
                TextField(
                  controller: _newWordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'ערך חדש',
                  ),
                ),
                SizedBox(height: 20.h),
        
                // DropdownButton for field selection
                const Text(
                  'בחר:',
                ),
                DropdownButton<String>(
                  value: _selectedItem,
                  hint: const Text('תבחר אופציה'),
                  isExpanded: true,
                  items: _dropdownItems.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedItem = newValue;
                    });
                  },
                ),
                SizedBox(height: 20.h),
        
                // Change Field Button (Moved above categories)
                ElevatedButton(
                  onPressed: _updateProduct,
                  child: const Text('תשנה'),
                ),
                SizedBox(height: 20.h),
        
                // Display Categories as Checkboxes
                const Text(
                  'בחר קטגוריה/ות:',
                ),
                SizedBox(height: 10.h),
                Wrap(
                  children: _categories.map((category) {
                    return CheckboxListTile(
                      title: Text(category.name),
                      value: _categorySelections[category.id],
                      onChanged: (bool? value) {
                        setState(() {
                          _categorySelections[category.id] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
        
                // Save Categories Button
                ElevatedButton(
                  onPressed: _saveCategoryChanges,
                  child: const Text('שמירה'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

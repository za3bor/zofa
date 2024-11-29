import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/models/category.dart';
import 'package:image_picker/image_picker.dart';

class AddNewProductScreen extends StatefulWidget {
  const AddNewProductScreen({super.key});
  @override
  State<AddNewProductScreen> createState() {
    return _AddNewProductScreenState();
  }
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image; // Variable to hold the selected image

  // Text controllers
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _dataController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _additionalFeaturesController = TextEditingController();
  final _containsController = TextEditingController();
  final _mayContainController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _priceController = TextEditingController();

  // Nutrition controllers
  final _caloriesController = TextEditingController();
  final _totalFatController = TextEditingController();
  final _saturatedFatController = TextEditingController();
  final _transFatController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _carbohydratesController = TextEditingController();
  final _sugarsController = TextEditingController();
  final _sugarTeaspoonsController = TextEditingController();
  final _sugarAlcoholsController = TextEditingController();
  final _dietaryFiberController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _calciumController = TextEditingController();
  final _ironController = TextEditingController();

  // Dropdown and toggle states
  bool _inStock = false;
  bool _isDrink = false;
  bool _isSeeds = false;

  bool _containsSodium = false;
  bool _containsSugar = false;
  bool _containsFat = false;
  bool _isGreen = false;

  bool _ofWhichF = false;
  bool _ofWhichC = false;

  // Categories and health symbols
  List<Category> _categories = []; // New list to hold categories
  final Map<int, bool> _categorySelections =
      {}; // Map to track category selections

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories on initialization
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        // Handle the case where no image was selected
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImage(String barcode) async {
    if (_image == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://$ipAddress:3000/api/uploadPicture'),
    );

    request.fields['filename'] = barcode;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      _image!.path,
      filename: '$barcode.jpg',
    ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await http.Response.fromStream(response);
        print('File uploaded successfully: ${responseBody.body}');
        // You can use the responseBody to show success or to do further actions
      } else {
        final responseBody = await http.Response.fromStream(response);
        print(
            'File upload failed with status: ${response.statusCode}, body: ${responseBody.body}');
        // Handle specific status codes and provide feedback
        if (response.statusCode == 400) {
          // Bad request
          print('Bad request: ${responseBody.body}');
        } else if (response.statusCode == 500) {
          // Server error
          print('Server error: ${responseBody.body}');
        } else {
          // Other errors
          print('Error: ${responseBody.body}');
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
      // Show a user-friendly message or log the error
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress:3000/api/getAllCategories'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _categories = jsonData.map((item) {
            return Category(
              id: item['id'], // Changed from 'ID' to 'id'
              name: item['name'], // Changed from 'שם_משתמש' to 'userName'
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

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _barcodeController.dispose();
    _nameController.dispose();
    _dataController.dispose();
    _ingredientsController.dispose();
    _additionalFeaturesController.dispose();
    _containsController.dispose();
    _mayContainController.dispose();
    _priceController.dispose();
    _caloriesController.dispose();
    _totalFatController.dispose();
    _saturatedFatController.dispose();
    _transFatController.dispose();
    _cholesterolController.dispose();
    _sodiumController.dispose();
    _carbohydratesController.dispose();
    _sugarsController.dispose();
    _sugarTeaspoonsController.dispose();
    _sugarAlcoholsController.dispose();
    _dietaryFiberController.dispose();
    _proteinsController.dispose();
    _calciumController.dispose();
    _ironController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  // Method to add a new product
  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      List<int> selectedCategories = _categorySelections.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<int> healthSymbols = [];
      if (_containsSodium) healthSymbols.add(1); // Example IDs
      if (_containsSugar) healthSymbols.add(2);
      if (_containsFat) healthSymbols.add(3);
      if (_isGreen) healthSymbols.add(4);

      final product = {
        "barcode": int.parse(_barcodeController.text),
        "name": _nameController.text,
        "data": _dataController.text,
        "ingredients": _ingredientsController.text,
        "additionalFeatures": _additionalFeaturesController.text,
        "contains": _containsController.text,
        "mayContain": _mayContainController.text,
        "allergies": _allergiesController.text,
        "price": double.parse(_priceController.text),
        "inStock": _inStock,
        "isDrink": _isDrink,
        "isSeeds": _isSeeds,
        "categories": selectedCategories,
        "nutrition": {
          "calories": _caloriesController.text,
          "totalFat": _totalFatController.text,
          "of_which_f": _ofWhichF,
          "saturatedFat": _saturatedFatController.text,
          "transFat": _transFatController.text,
          "cholesterol": _cholesterolController.text,
          "sodium": _sodiumController.text,
          "carbohydrates": _carbohydratesController.text,
          "of_which_c": _ofWhichC,
          "sugars": _sugarsController.text,
          "sugarTeaspoons": _sugarTeaspoonsController.text,
          "sugarAlcohols": _sugarAlcoholsController.text,
          "dietaryFiber": _dietaryFiberController.text,
          "proteins": _proteinsController.text,
          "calcium": _calciumController.text,
          "iron": _ironController.text,
        },
        "healthSymbols": healthSymbols,
      };

      try {
        final response = await http.post(
          Uri.parse('http://$ipAddress:3000/api/addNewProduct'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(product),
        );
        _uploadImage(_barcodeController.text); // Call the upload function
        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product added successfully!')),
            );
            Navigator.pop(context);
          }
        } else {
          final errorResponse = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${errorResponse['message']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding product: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הוסף מוצר חדש'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Picker Button
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('בחר תמונה'), // "Choose Image" in Hebrew
              ),
              if (_image != null)
                Image.file(
                  _image!,
                  height: 150,
                  width: 150,
                ),
              // Text Fields for general product details
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'ברקוד'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'יש להזין ברקוד'
                      : null, // "Enter barcode" in Hebrew
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'שם המוצר'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter product name' : null,
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _dataController,
                  decoration: const InputDecoration(labelText: 'מידע'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _ingredientsController,
                  decoration: const InputDecoration(labelText: 'מרכיבים'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _additionalFeaturesController,
                  decoration:
                      const InputDecoration(labelText: 'מאפיינים נוספים'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _containsController,
                  decoration: const InputDecoration(labelText: 'מכיל'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _mayContainController,
                  decoration: const InputDecoration(labelText: 'עלול להכיל'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(labelText: 'אלרגיות'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'מחיר'),
                  keyboardType: TextInputType.number,
                ),
              ),

              // Switches for product status
              SwitchListTile(
                title: const Text(
                  'במלאי',
                  textAlign: TextAlign.right,
                ),
                value: _inStock,
                onChanged: (value) => setState(() => _inStock = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SwitchListTile(
                title: const Text(
                  'משקה',
                  textAlign: TextAlign.right,
                ),
                value: _isDrink,
                onChanged: (value) => setState(() => _isDrink = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SwitchListTile(
                title: const Text(
                  'בזוראת',
                  textAlign: TextAlign.right,
                ),
                value: _isSeeds,
                onChanged: (value) => setState(() => _isSeeds = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Categories as SwitchListTiles
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text('קטגוריות',
                    textAlign: TextAlign.right,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ..._categories.map((category) {
                return SwitchListTile(
                  title: Text(
                    category.name,
                    textAlign: TextAlign.right,
                  ),
                  value: _categorySelections[category.id] ?? false,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      _categorySelections[category.id] =
                          value; // Update selection
                    });
                  },
                );
              }),
              const Text(
                'סימנים',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              SwitchListTile(
                title: const Text(
                  'נתרו',
                  textAlign: TextAlign.right,
                ),
                value: _containsSodium,
                onChanged: (value) => setState(() => _containsSodium = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SwitchListTile(
                title: const Text(
                  'סוכר',
                  textAlign: TextAlign.right,
                ),
                value: _containsSugar,
                onChanged: (value) => setState(() => _containsSugar = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SwitchListTile(
                title: const Text(
                  'שומן',
                  textAlign: TextAlign.right,
                ),
                value: _containsFat,
                onChanged: (value) => setState(() => _containsFat = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SwitchListTile(
                title: const Text(
                  'ירוק',
                  textAlign: TextAlign.right,
                ),
                value: _isGreen,
                onChanged: (value) => setState(() => _isGreen = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              // Nutrition Fields
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(labelText: 'קלוריות'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _totalFatController,
                  decoration: const InputDecoration(labelText: 'סה"כ שומן'),
                ),
              ),
              SwitchListTile(
                title: const Text(
                  'מתוכם',
                  textAlign: TextAlign.right,
                ),
                value: _ofWhichF,
                onChanged: (value) => setState(() => _ofWhichF = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _saturatedFatController,
                  decoration: const InputDecoration(labelText: 'שומן רווי'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _transFatController,
                  decoration: const InputDecoration(labelText: 'שומן טרנס'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _cholesterolController,
                  decoration: const InputDecoration(labelText: 'כולסטרול'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _sodiumController,
                  decoration: const InputDecoration(labelText: 'נתרן'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _carbohydratesController,
                  decoration: const InputDecoration(labelText: 'פחמימות'),
                ),
              ),
              SwitchListTile(
                title: const Text(
                  'מתוכם',
                  textAlign: TextAlign.right,
                ),
                value: _ofWhichC,
                onChanged: (value) => setState(() => _ofWhichC = value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _sugarsController,
                  decoration: const InputDecoration(labelText: 'סוכרים'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _sugarTeaspoonsController,
                  decoration: const InputDecoration(labelText: 'כפיות סוכר'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _sugarAlcoholsController,
                  decoration: const InputDecoration(labelText: 'אלכוהול סוכר'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _dietaryFiberController,
                  decoration:
                      const InputDecoration(labelText: 'סיבים תזונתיים'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _proteinsController,
                  decoration: const InputDecoration(labelText: 'חלבונים'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _calciumController,
                  decoration: const InputDecoration(labelText: 'סידן'),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: _ironController,
                  decoration: const InputDecoration(labelText: 'ברזל'),
                ),
              ),

              // Submit Button
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text('הוסף מוצר'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

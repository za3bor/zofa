import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';

class CustomNutritionalValues extends StatefulWidget {
  const CustomNutritionalValues({super.key});

  @override
  State<CustomNutritionalValues> createState() {
    return _CustomNutritionalValuesState();
  }
}

class _CustomNutritionalValuesState extends State<CustomNutritionalValues> {
  final _formKey = GlobalKey<FormState>();

  final _barcodeController = TextEditingController();
  final _fieldNameController = TextEditingController();
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
  final _potassiumController = TextEditingController();
  final _magnesiumController = TextEditingController();
  final _lauricAcidController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _barcodeController.dispose();
    _fieldNameController.dispose();
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
    _potassiumController.dispose();
    _magnesiumController.dispose();
    _lauricAcidController.dispose();
    super.dispose();
  }

  // Method to add a new product
  Future<void> _addCustomNutritionalValues() async {
    if (_formKey.currentState!.validate()) {
      final nutritionalValues = {
        "barcode": int.parse(_barcodeController.text),
        "fieldname": _fieldNameController.text,
        "calories": _caloriesController.text,
        "totalFat": _totalFatController.text,
        "saturatedFat": _saturatedFatController.text,
        "transFat": _transFatController.text,
        "cholesterol": _cholesterolController.text,
        "sodium": _sodiumController.text,
        "carbohydrates": _carbohydratesController.text,
        "sugars": _sugarsController.text,
        "sugarTeaspoons": _sugarTeaspoonsController.text,
        "sugarAlcohols": _sugarAlcoholsController.text,
        "dietaryFiber": _dietaryFiberController.text,
        "proteins": _proteinsController.text,
        "calcium": _calciumController.text,
        "iron": _ironController.text,
        "potassium": _potassiumController.text,
        "magnesium": _magnesiumController.text,
        "lauricAcid": _lauricAcidController.text,
      };

      try {
        final response = await http.post(
          Uri.parse('http://$ipAddress/api/addCustomNutritionalValues'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(nutritionalValues),
        );
        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Custom nutritional values added successfully!')),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding Custom nutritional values: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'ערכים תזונתיים מותאמים אישית'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'ברקוד'),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'יש להזין ברקוד'
                              : null, // "Enter barcode" in Hebrew
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _fieldNameController,
                  decoration: const InputDecoration(labelText: 'שם הטבלה'),
                ),
                SizedBox(height: 10.h),
                // Nutrition Fields
                TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(labelText: 'קלוריות'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _totalFatController,
                  decoration: const InputDecoration(labelText: 'סה"כ שומן'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _saturatedFatController,
                  decoration: const InputDecoration(labelText: 'שומן רווי'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _transFatController,
                  decoration: const InputDecoration(labelText: 'שומן טרנס'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _cholesterolController,
                  decoration: const InputDecoration(labelText: 'כולסטרול'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _sodiumController,
                  decoration: const InputDecoration(labelText: 'נתרן'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _carbohydratesController,
                  decoration: const InputDecoration(labelText: 'פחמימות'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _sugarsController,
                  decoration: const InputDecoration(labelText: 'סוכרים'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _sugarTeaspoonsController,
                  decoration: const InputDecoration(labelText: 'כפיות סוכר'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _sugarAlcoholsController,
                  decoration: const InputDecoration(labelText: 'אלכוהול סוכר'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _dietaryFiberController,
                  decoration: const InputDecoration(
                    labelText: 'סיבים תזונתיים',
                  ),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _proteinsController,
                  decoration: const InputDecoration(labelText: 'חלבונים'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _calciumController,
                  decoration: const InputDecoration(labelText: 'סידן'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _ironController,
                  decoration: const InputDecoration(labelText: 'ברזל'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _potassiumController,
                  decoration: const InputDecoration(labelText: 'אשלגן'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _magnesiumController,
                  decoration: const InputDecoration(labelText: 'מגנזיום'),
                ),
                SizedBox(height: 10.h),

                TextFormField(
                  controller: _lauricAcidController,
                  decoration: const InputDecoration(labelText: 'חומצה לאורית'),
                ),
                SizedBox(height: 15.h),

                // Submit Button
                ElevatedButton(
                  onPressed: _addCustomNutritionalValues,
                  child: const Text('הוסף מוצר'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

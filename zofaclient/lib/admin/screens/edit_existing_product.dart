import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';

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
    'מכיל': 'contain', // Example field name
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
  ]; // Dropdown options

  Future<void> _updateProduct() async {
    final String barcode = _barcodeController.text;
    final String newWord = _newWordController.text;
    final String? fieldInEnglish = _fieldMap[_selectedItem ?? ''];

    if (fieldInEnglish != null && newWord.isNotEmpty && barcode.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(
              'http://$ipAddress:3000/api/updateProductField'), // Updated route
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
          // Handle success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          _barcodeController.clear();
          _newWordController.clear();
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update product')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Unable to update product')),
        );
      }
    } else {
      // Show error if field or text is missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
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
        title: const Text('Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barcode TextField (Numbers only)
            const Text(
              'Enter Barcode:',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _barcodeController,
              keyboardType: TextInputType.number, // Restrict to numbers
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Barcode',
              ),
            ),
            const SizedBox(height: 20),

            // New Word TextField
            const Text(
              'Enter the new word:',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _newWordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New Word',
              ),
            ),
            const SizedBox(height: 20),

            // DropdownButton
            const Text(
              'Select an option:',
              style: TextStyle(fontSize: 18),
            ),
            DropdownButton<String>(
              value: _selectedItem,
              hint: const Text('Choose an option'),
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
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _updateProduct,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

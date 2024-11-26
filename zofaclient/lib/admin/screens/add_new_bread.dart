import 'package:flutter/material.dart';
import 'package:zofa_client/constant.dart';
import 'package:http/http.dart' as http;

class AddNewBread extends StatefulWidget {
  const AddNewBread({super.key});
  @override
  State<AddNewBread> createState() {
    return _AddNewBreadState();
  }
}

class _AddNewBreadState extends State<AddNewBread> {
  final _breadNameController = TextEditingController();
  final _breadPriceController = TextEditingController();
  final _breadQuantityController = TextEditingController();

  Future<void> _saveNewBread() async {
    final enteredName = _breadNameController.text.trim();
    final enteredAmount = double.tryParse(_breadPriceController.text);
    final enteredQuantity = int.tryParse(_breadQuantityController.text);

    // Validate inputs
    if (enteredName.isEmpty || 
        enteredAmount == null || 
        enteredAmount <= 0 || 
        enteredQuantity == null || 
        enteredQuantity <= 0) {
      _showSnackBar('נא למלא את כל השדות עם ערכים תקינים.', Colors.red);
      return;
    }

    final url = Uri.parse('http://$ipAddress:3000/api/addNewBreadType');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': enteredName,
          'price': enteredAmount,
          'quantity': enteredQuantity,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        _breadNameController.clear();
        _breadPriceController.clear();
        _breadQuantityController.clear();
        _showSnackBar('הלחם נוסף בהצלחה!', Colors.green);
      } else if (response.statusCode == 409) {
        _showSnackBar('שגיאה: הלחם כבר קיים.', Colors.orange);
      } else {
        _showSnackBar('שגיאה במערכת. נא לפנות לפאדי.', Colors.red);
      }
    } catch (error) {
      _showSnackBar('שגיאה ברשת. נסה שוב מאוחר יותר.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _breadNameController.dispose();
    _breadPriceController.dispose();
    _breadQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הוספת סוג לחם חדש'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 5),
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _breadNameController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'לחם חדש',
                ),
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
              ),
            ),
            const SizedBox(height: 5),
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                keyboardType: TextInputType.number,
                controller: _breadQuantityController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'כמות',
                ),
              ),
            ),
            const SizedBox(height: 5),
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                keyboardType: TextInputType.number,
                controller: _breadPriceController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'מחיר',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _saveNewBread,
              child: const Text('הוספה לחם'),
            ),
          ],
        ),
      ),
    );
  }
}

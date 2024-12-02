import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/models/category.dart';

class DeleteCategory extends StatefulWidget {
  const DeleteCategory({super.key});

  @override
  State<DeleteCategory> createState() {
    return _DeleteCategoryState();
  }
}

class _DeleteCategoryState extends State<DeleteCategory> {
  List<Category> _categories = []; // List to hold categories
  final Map<int, bool> _categorySelections = {}; // Map to track selections for categories
  int? _selectedCategoryId; // Store the selected category's ID

  // Fetch categories from the server
  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress:3000/api/getAllCategories'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _categories = jsonData.map((item) {
            return Category(
              id: item['id'], // Assuming 'id' is the correct key for category ID
              name: item['name'], // Assuming 'name' is the correct key for category name
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

  // Delete category function
  Future<void> _deleteCategory() async {
    if (_selectedCategoryId == null) {
      _showDialog('שגיאה', 'לא בחרת קטגוריה');
      return;
    }

    final url = Uri.parse('http://$ipAddress:3000/api/deleteCategory/$_selectedCategoryId');
    final response = await http.delete(url);

    if (!mounted) {
      return; // Check if the widget is still mounted
    }

    if (response.statusCode == 200) {
      _showDialog('הצלחה', 'הקטגוריה נמחקה בהצלחה');
      // Refresh the category list after deletion
    } else {
      _showDialog('שגיאה במערכת', 'התקשר לפאדי 0525707415');
    }
  }

  // Show dialog for errors or success
  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('אוקי'),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when the screen is initialized
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הסרת קטגוריה'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 5),
              // Dropdown to select category
              DropdownButton<int>(
                hint: const Text('בחר קטגוריה'),
                value: _selectedCategoryId,
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                },
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _deleteCategory, // Call delete directly
                child: const Text('הסרת קטגוריה'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

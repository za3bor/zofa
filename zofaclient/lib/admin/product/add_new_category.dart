import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddNewCategory extends StatefulWidget {
  const AddNewCategory({super.key});

  @override
  State<AddNewCategory> createState() {
    return _AddNewCategoryState();
  }
}

class _AddNewCategoryState extends State<AddNewCategory> {
  final _categoryController = TextEditingController();

  Future<void> _addNewCategory() async {
    if (_categoryController.text.isEmpty || _categoryController.text.trim().isEmpty) {
      _showDialog('לא תקין', 'תמלאא');
      return;
    }

    final url = Uri.parse('http://$ipAddress/api/addNewCategory');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': _categoryController.text}),
    );

    if (!mounted) {
      return; // Check if the widget is still mounted
    }

    if (response.statusCode == 201) {
      _categoryController.clear();
      _showDialog('הצלחה', 'הקטגוריה נוספה בהצלחה');
    } else if (response.statusCode == 409) {
      _showDialog('שגיאה', 'הקטגוריה כבר קיימת');
    } else {
      _showDialog('שגיאה במערכת', 'התקשר לפאדי 0525707415');
    }
  }

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
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'הוספת ניתונים חדשים',
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(18.w),
          child: Column(
            children: [
              SizedBox(height: 5.h),
              TextField(
                controller: _categoryController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'קטגוריה חדשה',
                ),
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
              ),
              ElevatedButton(
                onPressed: _addNewCategory,
                child: const Text('הוספה קטגוריה'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeleteProductScreen extends StatefulWidget {
  const DeleteProductScreen({super.key});
  @override
  State<DeleteProductScreen> createState() {
    return _DeleteProductScreenState();
  }
}

class _DeleteProductScreenState extends State<DeleteProductScreen> {
  final TextEditingController _productIdController = TextEditingController();
  String _message = '';
  String _error = '';

  Future<void> _deleteProduct(String id) async {
    setState(() {
      _message = '';
      _error = '';
    });

    try {
      final response = await http
          .delete(Uri.parse('http://$ipAddress/api/deleteProduct/$id'));

      if (response.statusCode == 200) {
        // Successfully deleted
        final successMessage =
            json.decode(response.body)['message'] ?? 'המוצר נמחק בהצלחה.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
          _productIdController.clear();
        }
      } else if (response.statusCode == 404) {
        // Product not found
        final errorMessage =
            json.decode(response.body)['error'] ?? 'המוצר לא נמצא.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // General error
        final errorMessage =
            json.decode(response.body)['error'] ?? 'שגיאה במחיקת המוצר.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Handle any network or other unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה ברשת: לא ניתן להתחבר לשרת.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'מחיקת מוצר',
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            children: [
              TextField(
                controller: _productIdController,
                decoration: const InputDecoration(
                  labelText: 'ברקוד',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  final productId = _productIdController.text.trim();
                  if (productId.isNotEmpty) {
                    _deleteProduct(productId);
                  }
                },
                child: const Text('מחיקה'),
              ),
              SizedBox(height: 20.h),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.green,
                      ),
                ),
              if (_error.isNotEmpty)
                Text(
                  _error,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.red,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';

class EditableTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final int barcode;
  final String fieldName;

  const EditableTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    required this.barcode,
    required this.fieldName,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  bool _isSaving = false;

  Future<void> _updateProduct() async {
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/updateProductField'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': widget.barcode, // Barcode is being used as the product ID
          'field': widget.fieldName,
          'newValue': widget.controller.text,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          // Handle success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully'),backgroundColor: Colors.green,),
          );
        }
      } else {
        if (mounted) {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update product'),backgroundColor: Colors.red,),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Unable to update product'),backgroundColor: Colors.red,),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isSaving = true;
                  });
                  await _updateProduct();
                  setState(() {
                    _isSaving = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child:
                    _isSaving
                        ? SizedBox(
                          height: 16.h,
                          width: 16.h,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text('שמור'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


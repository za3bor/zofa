import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';

class EditableCustomNutritionalTable extends StatefulWidget {
  final Map values;
  final Map<String, TextEditingController> controllers;
  final List<Map<String, String>> nutritionalFields;
  final int barcode;

  const EditableCustomNutritionalTable({
    super.key,
    required this.values,
    required this.controllers,
    required this.nutritionalFields,
    required this.barcode,
  });

  @override
  State<EditableCustomNutritionalTable> createState() =>
      _EditableCustomNutritionalTableState();
}

class _EditableCustomNutritionalTableState
    extends State<EditableCustomNutritionalTable> {
  Future<void> saveNutritionalValues() async {
    try {
      final Map<String, dynamic> payload = {};
      widget.controllers.forEach((key, controller) {
        payload[key] = controller.text;
      });

      final response = await http.post(
        Uri.parse('http://$ipAddress/api/saveCustomProductNutritionalValues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': widget.barcode, 'values': payload}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ערכים תזונתיים נשמרו בהצלחה')),
          );
        }
      } else {
        if (mounted) {
          // show the raw error text
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה (${response.statusCode}): ${response.body}'),
            ),
          );
          debugPrint(
            'SAVE_NUTRI ERROR: ${response.statusCode} → ${response.body}',
          );
        }
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exception: $e')));
        debugPrint('SAVE_NUTRI EXCEPTION: $e\n$st');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return const Text('אין ערכים תזונתיים זמינים.');
    }

    List<TableRow> rows = [];

    for (var item in widget.nutritionalFields) {
      final label = item['label']!;
      final key = item['key']!;
      final controller = widget.controllers[key];
      if (controller == null) continue;

      rows.add(
        TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
          children: rows,
        ),
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: saveNutritionalValues,
            icon: const Icon(Icons.save),
            label: Text('שמור'),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';

class EditableNutritionalTable extends StatefulWidget {
  final Map<String, dynamic> values;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> booleanValues;
  final List<Map<String, String>> nutritionalFields;
  final int barcode;

  const EditableNutritionalTable({
    super.key,
    required this.values,
    required this.controllers,
    required this.booleanValues,
    required this.nutritionalFields,
    required this.barcode,
  });

  @override
  State<EditableNutritionalTable> createState() =>
      _EditableNutritionalTableState();
}

class _EditableNutritionalTableState extends State<EditableNutritionalTable> {
  Future<void> _saveNutritionalValues() async {
    try {
      final Map<String, dynamic> payload = {};

      for (final field in widget.nutritionalFields) {
        final key = field['key']!;
        final type = field['type']!;

        if (type == 'bool') {
          // boolean field
          final boolValue = widget.booleanValues[key] ?? false;
          payload[key] = boolValue ? 1 : 0;
        } else {
          // string or numeric field, try to parse double else send as string
          final controller = widget.controllers[key];
          if (controller != null) {
            final textValue = controller.text.trim();
            final doubleValue = double.tryParse(textValue);
            payload[key] = doubleValue ?? textValue;
          } else {
            payload[key] = null; // or empty string if preferred
          }
        }
      }

      final response = await http.post(
        Uri.parse('http://$ipAddress/api/saveProductNutritionalValues'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה (${response.statusCode}): ${response.body}'),
            ),
          );
        }
        debugPrint(
          'SAVE_NUTRI ERROR: ${response.statusCode} → ${response.body}',
        );
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exception: $e')));
      }
      debugPrint('SAVE_NUTRI EXCEPTION: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return const Text('אין ערכים תזונתיים זמינים.');
    }

    final List<TableRow> rows = [];

    for (final field in widget.nutritionalFields) {
      final label = field['label']!;
      final key = field['key']!;
      final isBool = widget.booleanValues.containsKey(key);

      Widget input;
      if (isBool) {
        bool current = widget.booleanValues[key]!;
        input = StatefulBuilder(
          builder:
              (ctx, setState) => Switch(
                value: current,
                onChanged: (v) {
                  setState(() => current = v);
                  widget.booleanValues[key] = v;
                },
              ),
        );
      } else {
        final controller = widget.controllers[key];
        if (controller == null) continue;

        input = TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 4.h,
            ),
          ),
        );
      }

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
            Padding(padding: EdgeInsets.all(8.0.w), child: input),
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
            onPressed: _saveNutritionalValues,
            icon: const Icon(Icons.save),
            label: const Text('שמור'),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';
import 'package:zofa/models/sale_item.dart';

enum DealType { single, bundle, chooseXofN }

class SelectedProductsScreen extends StatefulWidget {
  final List<SaleItem> items;
  final void Function(List<SaleItem>, double, DateTime, DateTime, String)
  onUpdate;

  const SelectedProductsScreen({
    super.key,
    required this.items,
    required this.onUpdate,
  });

  @override
  State<SelectedProductsScreen> createState() => _SelectedProductsScreenState();
}

class _SelectedProductsScreenState extends State<SelectedProductsScreen> {
  late List<SaleItem> items;
  DealType dealType = DealType.single;
  int chooseCount = 0;
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final oldPriceController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    items =
        widget.items
            .map((e) => SaleItem(product: e.product, quantity: e.quantity))
            .toList();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    oldPriceController.dispose();
    super.dispose();
  }

  double get originalTotal =>
      items.fold(0.0, (sum, i) => sum + i.product.price * i.quantity);

  Future<void> pickDate(bool isStart) async {
    final now = DateTime.now();
    final first = isStart ? now : (startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(picked)) endDate = null;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void updateQuantity(int index, String v) {
    final qty = int.tryParse(v) ?? 1;
    setState(() => items[index].quantity = qty);
  }

  void removeItem(int i) => setState(() => items.removeAt(i));

  Future<void> sendSaleNotification() async {
    final url = Uri.parse(
      'http://$ipAddress/api/sendSaleNotification',
    ); // Replace with your actual backend URL

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: ${response.body}'),
          ),
        );
      }
    }
  }

  Future<void> submit() async {
    // Enforce exactly one item for single-item deal
    if (dealType == DealType.single && items.length != 1) {
      return _showError(
        'For a single-item discount, please select exactly one product.',
      );
    }
    final name = nameController.text.trim();
    if (name.isEmpty) return _showError('יש להזין שם למבצע');
    final price = double.tryParse(priceController.text) ?? -1;
    if (price < 0) return _showError('יש להזין מחיר מבצע תקין');
    if (startDate == null) return _showError('יש לבחור תאריך התחלה');
    if (endDate == null) return _showError('יש לבחור תאריך סיום');
    if (endDate!.isBefore(startDate!)) {
      return _showError('תאריך הסיום לפני ההתחלה');
    }

    double oldPrice = originalTotal;
    if (dealType == DealType.chooseXofN) {
      oldPrice = double.tryParse(oldPriceController.text) ?? -1;
      if (oldPrice < 0) return _showError('יש להזין מחיר רגיל ל-X');
    }

    final payload = {
      'name': name,
      'items':
          items
              .map((e) => {'product_id': e.product.id, 'quantity': e.quantity})
              .toList(),
      'deal_type': dealType.toString().split('.').last,
      if (dealType == DealType.chooseXofN) 'choose_count': chooseCount,
      'price': price,
      'original_price': oldPrice,
      'start_date': startDate!.toIso8601String().split('T').first,
      'end_date': endDate!.toIso8601String().split('T').first,
    };

    setState(() => isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/createSale'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 201) {
        widget.onUpdate(items, price, startDate!, endDate!, name);
        //await sendSaleNotification();
        if (mounted) Navigator.pop(context);
      } else {
        _showError('שמירה נכשלה: ${response.statusCode}');
      }
    } catch (e) {
      _showError('שגיאת רשת: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('שגיאה'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('אוקיי'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'הגדרת מבצע'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'שם המבצע',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
        
              // 2. Deal Type + X & Old Price
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'סוג מבצע',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DealType>(
                        value: dealType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => dealType = v!),
                        items: const [
                          DropdownMenuItem(
                            value: DealType.single,
                            child: Text('הנחה על מוצר בודד'),
                          ),
                          DropdownMenuItem(
                            value: DealType.bundle,
                            child: Text('באנדל מוצרים'),
                          ),
                          DropdownMenuItem(
                            value: DealType.chooseXofN,
                            child: Text('בחירת X מתוך N'),
                          ),
                        ],
                      ),
                      if (dealType == DealType.chooseXofN) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: chooseCount.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'X פריטים לבחירה',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged:
                                    (v) => setState(
                                      () => chooseCount = int.tryParse(v) ?? 0,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: oldPriceController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'מחיר רגיל ל-X',
                                  prefixText: '₪ ',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
        
              // 3. Dates
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => pickDate(true),
                          label: Text(
                            startDate == null
                                ? 'בחר התחלה'
                                : startDate!.toLocal().toString().split(' ')[0],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => pickDate(false),
                          label: Text(
                            endDate == null
                                ? 'בחר סיום'
                                : endDate!.toLocal().toString().split(' ')[0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
        
              // 4. Items
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'מוצרים נבחרים',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...items.asMap().entries.map((e) {
                        final i = e.key;
                        final si = e.value;
                        return Card(
                          color: Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://d1qq705dywrog2.cloudfront.net/images/${si.product.id}.jpeg',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        si.product.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text('כמות:'),
                                          const SizedBox(width: 8),
                                          dealType == DealType.chooseXofN
                                              ? const Text(
                                                '1',
                                              ) // Show fixed quantity
                                              : SizedBox(
                                                width: 50,
                                                height: 32,
                                                child: TextFormField(
                                                  initialValue:
                                                      si.quantity.toString(),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                          horizontal: 8,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                  onChanged:
                                                      (v) => updateQuantity(i, v),
                                                ),
                                              ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₪${(si.product.price * si.quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => removeItem(i),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
        
              // 5. Price & Submit
              if (dealType != DealType.chooseXofN) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'מחיר וסיכום',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('סה"כ לפני: ₪${originalTotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'מחיר לאחר הנחה',
                            prefixText: '₪ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                isSaving
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'שמור מבצע',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'מחיר וסיכום',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'סה"כ לפני (ל-X): ₪${double.tryParse(oldPriceController.text)?.toStringAsFixed(2) ?? ''}',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'מחיר לאחר הנחה',
                            prefixText: '₪ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                isSaving
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'שמור מבצע',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

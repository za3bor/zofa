import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BreadQuantityRow extends StatefulWidget {
  const BreadQuantityRow({
    required this.name,
    required this.price,
    required this.onQuantitySelected,
    required this.quantity,
    super.key,
  });

  final String name;
  final double price;
  final int quantity;
  final Function(int) onQuantitySelected;

  @override
  State<BreadQuantityRow> createState() {
    return _BreadQuantityRowState();
  }
}

class _BreadQuantityRowState extends State<BreadQuantityRow> {
  int quantity = 0;

  void increaseQuantity() {
    setState(() {
      quantity++;
      widget.onQuantitySelected(quantity);
    });
  }

  void decreaseQuantity() {
    if (quantity > 0) {
      setState(() {
        quantity--;
        widget.onQuantitySelected(quantity);
      });
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 222, 210, 206), // Light background color
        borderRadius: BorderRadius.circular(12.r), // Rounded corners
        boxShadow: const [
          BoxShadow(
            color: Colors.black26, // Shadow color
            offset: Offset(0, 2), // Shadow offset
            blurRadius: 6.0, // Shadow blur
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w), // Margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          const Text(
            '(מעורבב עם קמח מלא בלי תוספת סוכר)',
            style: TextStyle(
              color: Color.fromARGB(255, 98, 98, 98),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              // Price section
              Expanded(
                flex: 1,
                child: Text(
                  '₪ ${widget.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Quantity control section
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: increaseQuantity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: const Icon(Icons.add, color: Colors.brown),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: decreaseQuantity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: const Icon(Icons.remove, color: Colors.brown),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity available section
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${widget.quantity} יח',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
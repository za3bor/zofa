import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
          ),
          const SizedBox(height: 8.0),
          const Text(
            '(מעורבב עם קמח מלא בלי תוספת סוכר)',
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '₪ ${widget.price.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: increaseQuantity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.add),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      quantity.toString(),
                    ),
                    const SizedBox(width: 8.0),
                    InkWell(
                      onTap: decreaseQuantity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.remove),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

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
        color: const Color.fromARGB(255, 222, 210, 206), // Light background color
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black26, // Shadow color
            offset: Offset(0, 2), // Shadow offset
            blurRadius: 6.0, // Shadow blur
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            '(מעורבב עם קמח מלא בלי תוספת סוכר)',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              // Price section
              Expanded(
                flex: 1,
                child: Text(
                  '₪ ${widget.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14.0,
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
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.add, color: Colors.brown),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
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
                          child: Icon(Icons.remove, color: Colors.brown),
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
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
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
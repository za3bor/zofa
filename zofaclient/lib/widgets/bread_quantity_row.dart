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
        color: Theme.of(context).cardColor, // Use the card color from ThemeData
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold, // Customize weight for the title
                  ) ??
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '₪ ${widget.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge, // Use bodyLarge text style
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0, // Adjust the font size if needed
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
                      style: Theme.of(context).textTheme.bodyLarge, // Use bodyLarge text style
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
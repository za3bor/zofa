import 'package:flutter/material.dart';
import 'package:zofa_client/admin/screens/add_new_product.dart';
import 'package:zofa_client/admin/screens/add_new_category.dart';
import 'package:zofa_client/admin/screens/admin_p_orders.dart';
import 'package:zofa_client/admin/screens/delete_product.dart';
import 'package:zofa_client/admin/screens/edit_existing_product.dart';
import 'package:zofa_client/admin/screens/edit_product_stock.dart';
import 'package:zofa_client/admin/widgets/custom_elevated_but.dart';

class ProductFuncScreen extends StatelessWidget {
  const ProductFuncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ProductFunc Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Two columns
          mainAxisSpacing: 20.0, // Spacing between rows
          crossAxisSpacing: 20.0, // Spacing between columns
          childAspectRatio: 1.5, // Aspect ratio for button sizing
          children: const [
            CustomElevatedButton(
              label: 'הוספת קטגוריה חדשה',
              targetPage: AddNewCategory(),
              color: Colors.teal, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'הוספת מוצר חדש',
              targetPage: AddNewProductScreen(),
              color: Colors.blue, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'צפייה בהזמנות מוצרים',
              targetPage: ProductOrdersScreen(),
              color: Colors.red, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'edit exicting product',
              targetPage: EditExistingProductScreen(),
              color: Colors.teal, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'Delete exicting product',
              targetPage: DeleteProductScreen(),
              color: Colors.teal, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'edit stock product',
              targetPage: EditProductStockScreen(),
              color: Color.fromARGB(255, 55, 56, 89), // Custom color for this button
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100], // Light background color
    );
  }
}

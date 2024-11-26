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
          'לוח בקרה למוצרים',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Two columns
          mainAxisSpacing: 16.0, // Reduced spacing for a more compact layout
          crossAxisSpacing: 16.0, // Reduced spacing
          childAspectRatio:
              1.4, // Adjusted aspect ratio for better button sizing
          children: const [
            CustomElevatedButton(
              label: 'הוספת קטגוריה חדשה',
              targetPage: AddNewCategory(),
            ),
            CustomElevatedButton(
              label: 'הוספת מוצר חדש',
              targetPage: AddNewProductScreen(),
            ),
            CustomElevatedButton(
              label: 'צפייה בהזמנות מוצרים',
              targetPage: ProductOrdersScreen(),
            ),
            CustomElevatedButton(
              label: 'עריכת מוצר קיים',
              targetPage: EditExistingProductScreen(),
            ),
            CustomElevatedButton(
              label: 'מחק מוצר קיים',
              targetPage: DeleteProductScreen(),
            ),
            CustomElevatedButton(
              label: 'עריכת מלאי מוצר',
              targetPage: EditProductStockScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

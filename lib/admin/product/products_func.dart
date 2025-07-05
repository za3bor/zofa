import 'package:flutter/material.dart';
import 'package:zofa/admin/product/add_new_product.dart';
import 'package:zofa/admin/product/add_new_category.dart';
import 'package:zofa/admin/product/admin_p_orders.dart';
import 'package:zofa/admin/product/custom_nutritional_values.dart';
import 'package:zofa/admin/product/delete_category.dart';
import 'package:zofa/admin/product/edit_product_stock.dart';
import 'package:zofa/admin/sales/create_sale_page.dart';
import 'package:zofa/admin/sales/sales_list.dart';
import 'package:zofa/widgets/custom_appbar.dart';
import 'package:zofa/widgets/custom_elevated_but.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductFuncScreen extends StatelessWidget {
  const ProductFuncScreen({super.key});
  bool isFoldableDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Foldable devices tend to have a very wide aspect ratio when unfolded
    final aspectRatio = screenWidth / screenHeight;

    // Define a threshold for foldable device detection
    return aspectRatio > 2.0 || screenWidth > 500;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'לוח בקרה למוצרים'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2, // Two columns
            mainAxisSpacing: 16.0.w, // Adjusted spacing for a cleaner look
            crossAxisSpacing: 16.0.h, // Adjusted spacing
            childAspectRatio:
                isFoldableDevice(context)
                    ? 1.15.w
                    : 1.4.w, // Slightly adjusted aspect ratio
            children: [
              const CustomElevatedButton(
                label: 'הוספת קטגוריה חדשה',
                targetPage: AddNewCategory(),
              ),
              const CustomElevatedButton(
                label: 'הוספת מוצר חדש',
                targetPage: AddNewProductScreen(),
              ),
              const CustomElevatedButton(
                label: 'הוספת ערכים תזונתיים נוספים',
                targetPage: CustomNutritionalValues(),
              ),
              const CustomElevatedButton(
                label: 'צפייה בהזמנות מוצרים',
                targetPage: ProductOrdersScreen(),
              ),
              const CustomElevatedButton(
                label: 'עריכת מוצר',
                targetPage: EditProductStockScreen(),
              ),
              const CustomElevatedButton(
                label: 'מחיקת קטגוריה',
                targetPage: DeleteCategory(),
              ),
              CustomElevatedButton(
                label: 'Create sale',
                targetPage: ProductSelectionPage(),
              ),
              CustomElevatedButton(
                label: 'Delete sale',
                targetPage: SalesButtonsScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

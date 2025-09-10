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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              int crossAxisCount = 2;
              if (width >= 1200) {
                crossAxisCount = 4;
              } else if (width >= 800) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16.0.h,
                  crossAxisSpacing: 16.0.w,
                  childAspectRatio: isFoldableDevice(context) ? 1.05.w : 1.25.w,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return const CustomElevatedButton(
                        label: 'הוספת מוצר חדש',
                        targetPage: AddNewProductScreen(),
                        icon: Icons.add_box_outlined,
                      );

                    case 1:
                      return const CustomElevatedButton(
                        label: 'הוספת קטגוריה חדשה',
                        targetPage: AddNewCategory(),
                        icon: Icons.category_outlined,
                      );
                    case 2:
                      return const CustomElevatedButton(
                        label: 'הוספת ערכים תזונתיים נוספים',
                        targetPage: CustomNutritionalValues(),
                        icon: Icons.pie_chart_outline,
                      );
                    case 3:
                      return const CustomElevatedButton(
                        label: 'צפייה בהזמנות מוצרים',
                        targetPage: ProductOrdersScreen(),
                        icon: Icons.receipt_long_outlined,
                      );
                    case 4:
                      return const CustomElevatedButton(
                        label: 'עריכת/מחיקת מוצר',
                        targetPage: EditProductStockScreen(),
                        icon: Icons.edit_note_outlined,
                      );
                    case 5:
                      return const CustomElevatedButton(
                        label: 'מחיקת קטגוריה',
                        targetPage: DeleteCategory(),
                        icon: Icons.delete_outline,
                      );
                    case 6:
                      return CustomElevatedButton(
                        label: 'הוספת מבצע',
                        targetPage: ProductSelectionPage(),
                        icon: Icons.local_mall_outlined,
                      );
                    default:
                      return CustomElevatedButton(
                        label: 'עריכת/מחיקת מבצע',
                        targetPage: SalesButtonsScreen(),
                        icon: Icons.remove_shopping_cart_outlined,
                      );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:zofa_client/admin/add_admin.dart';
import 'package:zofa_client/admin/bread/bread_func.dart';
import 'package:zofa_client/admin/coupons.dart';
import 'package:zofa_client/admin/notes.dart';
import 'package:zofa_client/admin/product/products_func.dart';
import 'package:zofa_client/widgets/custom_elevated_but.dart';
import 'package:zofa_client/customer/tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminMainPageScreen extends StatelessWidget {
  const AdminMainPageScreen({super.key});

  bool isFoldableDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    double width = View.of(context).physicalSize.width;
    double height = View.of(context).physicalSize.height;
    // Foldable devices tend to have a very wide aspect ratio when unfolded
    final aspectRatio = screenWidth / screenHeight;

    print('PHHH Screen width: $width'
        'PHHH Screen height: $height');

    // Define a threshold for foldable device detection
    print('Aspect ratio: $aspectRatio'
        'Screen width: $screenWidth'
        'Screen height: $screenHeight');
    return aspectRatio > 2.0 || screenWidth > 500;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('לוח בקרה למנהל'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2, // Two columns
            mainAxisSpacing: 16.0.w, // Adjusted spacing for a cleaner look
            crossAxisSpacing: 16.0.h, // Adjusted spacing
            childAspectRatio: isFoldableDevice(context)
                ? 1.15.w
                : 1.4.w, // Slightly adjusted aspect ratio
            children: const [
              CustomElevatedButton(
                label: 'מוצרים',
                targetPage: ProductFuncScreen(),
              ),
              CustomElevatedButton(
                label: 'לחם',
                targetPage: BreadFuncScreen(),
              ),
              CustomElevatedButton(
                label: 'לקוחות',
                targetPage: TabsScreen(),
              ),
              CustomElevatedButton(
                label: 'הערות',
                targetPage: NotesScreen(),
              ),
              CustomElevatedButton(
                label: 'קופונים',
                targetPage: CouponsScreen(),
              ),
              CustomElevatedButton(
                label: 'מנהלים',
                targetPage: AddAdminScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

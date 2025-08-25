import 'package:flutter/material.dart';
import 'package:zofa/admin/add_admin.dart';
import 'package:zofa/admin/bread/bread_func.dart';
import 'package:zofa/admin/coupons.dart';
import 'package:zofa/admin/notes.dart';
import 'package:zofa/admin/product/products_func.dart';
import 'package:zofa/widgets/custom_appbar.dart';
import 'package:zofa/widgets/custom_elevated_but.dart';
import 'package:zofa/customer/tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminMainPageScreen extends StatelessWidget {
  const AdminMainPageScreen({super.key});

  bool isFoldableDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Foldable devices tend to have a very wide aspect ratio when unfolded
    final aspectRatio = screenWidth / screenHeight;
    return aspectRatio > 2.0 || screenWidth > 500;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'לוח בקרה למנהל',
      ),
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
                itemCount: 6,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return CustomElevatedButton(
                        label: 'מוצרים',
                        targetPage: const ProductFuncScreen(),
                        icon: Icons.widgets_outlined,
                      );
                    case 1:
                      return CustomElevatedButton(
                        label: 'לחם',
                        targetPage: const BreadFuncScreen(),
                        icon: Icons.bakery_dining_outlined,
                      );
                    case 2:
                      return CustomElevatedButton(
                        label: 'לקוחות',
                        targetPage: const TabsScreen(),
                        icon: Icons.group_outlined,
                      );
                    case 3:
                      return CustomElevatedButton(
                        label: 'הערות',
                        targetPage: const NotesScreen(),
                        icon: Icons.sticky_note_2_outlined,
                      );
                    case 4:
                      return CustomElevatedButton(
                        label: 'קופונים',
                        targetPage: const CouponsScreen(),
                        icon: Icons.local_offer_outlined,
                      );
                    default:
                      return CustomElevatedButton(
                        label: 'מנהלים',
                        targetPage: const AddAdminScreen(),
                        icon: Icons.admin_panel_settings_outlined,
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

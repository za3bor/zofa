import 'package:flutter/material.dart';
import 'package:zofa/admin/bread/admin_bread_orders.dart';
import 'package:zofa/admin/bread/add_new_bread.dart';
import 'package:zofa/admin/bread/change_bread_price.dart';
import 'package:zofa/admin/bread/delete_bread.dart';
import 'package:zofa/constant.dart';
import 'package:zofa/widgets/custom_elevated_but.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BreadFuncScreen extends StatelessWidget {
  const BreadFuncScreen({super.key});

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
      appBar: const CustomAppBar(
        title: 'לוח בקרה ללחם',
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
                itemCount: 5,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return const CustomElevatedButton(
                        label: 'הוספת סוג לחם חדש',
                        targetPage: AddNewBread(),
                        icon: Icons.add_circle_outline,
                      );
                    case 1:
                      return const CustomElevatedButton(
                        label: 'צפייה בהזמנות לחם יום שלישי',
                        targetPage: AdminBreadOrdersScreen(day: "שלישי"),
                        icon: Icons.event_note_outlined,
                      );
                    case 2:
                      return const CustomElevatedButton(
                        label: 'צפייה בהזמנות לחם יום שישי',
                        targetPage: AdminBreadOrdersScreen(day: "שישי"),
                        icon: Icons.event_note_outlined,
                      );
                    case 3:
                      return const CustomElevatedButton(
                        label: 'עדכון מחירי לחם',
                        targetPage: BreadPriceUpdateScreen(),
                        icon: Icons.price_change_outlined,
                      );
                    default:
                      return const CustomElevatedButton(
                        label: 'מחיקת סוגי לחם',
                        targetPage: BreadDeleteScreen(),
                        icon: Icons.delete_sweep_outlined,
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

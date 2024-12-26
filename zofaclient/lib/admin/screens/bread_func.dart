import 'package:flutter/material.dart';
import 'package:zofa_client/admin/screens/admin_bread_orders.dart';
import 'package:zofa_client/admin/screens/add_new_bread.dart';
import 'package:zofa_client/admin/widgets/custom_elevated_but.dart';
import 'package:zofa_client/widgets/snow_layer.dart';
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
    print('Aspect ratio: $aspectRatio' + 'Screen width: $screenWidth');
    return aspectRatio > 2.0 || screenWidth > 500;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
                flexibleSpace: const SnowLayer(), // Directly use SnowLayer without Container

        title: const Text(
          'לוח בקרה ללחם',
        ),
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
                label: 'הוספת סוג לחם חדש',
                targetPage: AddNewBread(),
              ),
              CustomElevatedButton(
                label: 'צפייה בהזמנות לחם יום שלישי',
                targetPage: AdminBreadOrdersScreen(day: "שלישי"),
              ),
              CustomElevatedButton(
                label: 'צפייה בהזמנות לחם יום שישי',
                targetPage: AdminBreadOrdersScreen(day: "שישי"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

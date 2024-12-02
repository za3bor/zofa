import 'package:flutter/material.dart';
import 'package:zofa_client/admin/screens/admin_bread_orders.dart';
import 'package:zofa_client/admin/screens/add_new_bread.dart';
import 'package:zofa_client/admin/widgets/custom_elevated_but.dart';

class BreadFuncScreen extends StatelessWidget {
  const BreadFuncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            mainAxisSpacing: 16.0, // Reduced spacing for a more compact layout
            crossAxisSpacing: 16.0, // Reduced spacing
            childAspectRatio:
                1.4, // Adjusted aspect ratio for better button sizing
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

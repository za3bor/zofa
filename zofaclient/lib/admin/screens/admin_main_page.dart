import 'package:flutter/material.dart';
import 'package:zofa_client/admin/screens/bread_func.dart';
import 'package:zofa_client/admin/screens/coupons.dart';
import 'package:zofa_client/admin/screens/notes.dart';
import 'package:zofa_client/admin/screens/products_func.dart';
import 'package:zofa_client/admin/widgets/custom_elevated_but.dart';
import 'package:zofa_client/screens/tabs.dart';
import 'package:zofa_client/widgets/snow_layer.dart';

class AdminMainPageScreen extends StatelessWidget {
  const AdminMainPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const SnowLayer(), // Directly use SnowLayer without Container
        title: const Text(
          'לוח בקרה למנהל',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Two columns
          mainAxisSpacing: 16.0, // Adjusted spacing for a cleaner look
          crossAxisSpacing: 16.0, // Adjusted spacing
          childAspectRatio: 1.4, // Slightly adjusted aspect ratio
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
          ],
        ),
      ),
    );
  }
}

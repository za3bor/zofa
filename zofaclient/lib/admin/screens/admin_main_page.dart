import 'package:flutter/material.dart';
import 'package:zofa_client/admin/screens/bread_func.dart';
import 'package:zofa_client/admin/screens/coupons.dart';
import 'package:zofa_client/admin/screens/notes.dart';
import 'package:zofa_client/admin/screens/products_func.dart';
import 'package:zofa_client/admin/widgets/custom_elevated_but.dart';
import 'package:zofa_client/screens/tabs.dart';

class AdminMainPageScreen extends StatelessWidget {
  const AdminMainPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
              label: 'מוצרים',
              targetPage: ProductFuncScreen(),
              color: Colors.green, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'לחם',
              targetPage: BreadFuncScreen(),
              color: Colors.green, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'לקוח',
              targetPage: TabsScreen(),
              color: Colors.green, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'notes',
              targetPage: NotesScreen(),
              color: Colors.green, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'coupon',
              targetPage: CouponsScreen(),
              color: Colors.red, // Custom color for this button
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100], // Light background color
    );
  }
}

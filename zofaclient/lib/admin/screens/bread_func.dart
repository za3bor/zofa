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
          'BreadFunc Dashboard',
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
              label: 'הוספת סוג לחם חדש',
              targetPage: AddNewBread(),
              color: Colors.orange, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'צפייה בהזמנות לחם יום שלישי',
              targetPage: AdminBreadOrdersScreen(day: "שלישי",),
              color: Colors.purple, // Custom color for this button
            ),
            CustomElevatedButton(
              label: 'צפייה בהזמנות לחם יום שישי',
              targetPage: AdminBreadOrdersScreen(day: "שישי",),
              color: Colors.purple, // Custom color for this button
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100], // Light background color
    );
  }
}

import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String label;
  final Widget targetPage;
  final Color color; // New color property for button customization

  const CustomElevatedButton({
    super.key,
    required this.label,
    required this.targetPage,
    required this.color, // Add required color property
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Use the passed color for button background
        foregroundColor: Colors.white, // White text color
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        textStyle: const TextStyle(
          fontSize: 18, // Bigger text size
          fontWeight: FontWeight.w500, // Medium weight for text
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners
        ),
        elevation: 8, // Add shadow for depth
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

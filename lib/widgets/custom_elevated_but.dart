import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomElevatedButton extends StatelessWidget {
  final String label;
  final Widget targetPage;
  final IconData? icon;

  const CustomElevatedButton({
    super.key,
    required this.label,
    required this.targetPage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12.r), // Rounded corners for a modern look
        ),
        elevation: 2,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 28.sp,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            SizedBox(height: 8.h),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold
                ),
          ),
        ],
      ),
    );
  }
}

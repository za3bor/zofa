import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 150.h,
            ),
            SizedBox(height: 20.h),
            Text(
              'העגלה שלך ריקה!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('חזור לחנות'),
            ),
          ],
        ),
      ),
    );
  }
}

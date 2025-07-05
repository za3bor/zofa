import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color brown = const Color(0xFF6D4C41); // Match your brand

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 150.h, color: brown),
            SizedBox(height: 20.h),
            Text(
              'העגלה שלך ריקה!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 10.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'חזור לחנות',
                style: GoogleFonts.assistant(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                minimumSize: Size(180.w, 48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  side: BorderSide(color: brown),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  // Helper function to launch a URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url); // Parse the URL to a Uri object

    try {
      if (await canLaunchUrl(uri)) {
        // Check if the URL can be launched
        await launchUrl(uri,
            mode: LaunchMode.externalApplication); // Try to open in the app
      } else {
        // If app can't open, open it in the browser
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      throw 'Could not launch $url: $e'; // Handle error if URL cannot be launched
    }
  }

  // Build Icon Button with image from URL
  Widget _buildIconButton({
    required String iconUrl,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.network(
        iconUrl,
        width: 30.w,
        height: 30.h,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Replace with your actual URLs
    const String linkedinUrl = 'https://www.linkedin.com/in/fadi-srour';
    const String emailUrl = 'mailto:fadisrour.zarbor@gmail.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('אודות האפליקציה'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to the right
            children: [
              // App name
              Text(
                'שם האפליקציה: Zofa Health Shop', // App name in Hebrew
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 20.h),
              Text(
                'גרסה: 3.02.4', // App name in Hebrew
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 20.h),
              // Developer name
              Text(
                'מפתח: פאדי סרור', // Developer's name in Hebrew
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 20.h),
              // Contact section title
              Text(
                'צור קשר:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 20.h),
              // LinkedIn link
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .start, // Align icons and text to the right
                children: [
                  _buildIconButton(
                    iconUrl:
                        "https://img.icons8.com/ios-glyphs/60/000000/linkedin.png", // LinkedIn icon
                    onPressed: () => _launchURL(linkedinUrl),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _launchURL(linkedinUrl),
                    child: Text(
                      'פאדי סרור', // LinkedIn name in Hebrew
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Email link
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .start, // Align icons and text to the right
                children: [
                  _buildIconButton(
                    iconUrl:
                        "https://img.icons8.com/ios-glyphs/60/000000/email.png", // Email icon
                    onPressed: () => _launchURL(emailUrl),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _launchURL(emailUrl),
                    child: Text(
                      'fadisrour.zarbor@gmail.com', // Email address in Hebrew
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

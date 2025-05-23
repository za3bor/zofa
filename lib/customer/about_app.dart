import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zofa/constant.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  // Helper function to launch a URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url); // Parse the URL to a Uri object

    try {
      if (await canLaunchUrl(uri)) {
        // Check if the URL can be launched
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        ); // Try to open in the app
      } else {
        // If app can't open, open it in the browser
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      throw 'Could not launch $url: $e'; // Handle error if URL cannot be launched
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  Future<String> _checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      return currentVersion; // Return the current version
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('בדיקת הגרסה נכשלה. אנא נסה שוב מאוחר יותר.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return ''; // Return a default value in case of error
    }
  }

  // Build Icon Button with image from URL
  Widget _buildIconButton({
    required String iconUrl,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.network(iconUrl, width: 30.w, height: 30.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Replace with your actual URLs
    const String linkedinUrl = 'https://www.linkedin.com/in/fadi-srour';
    const String emailUrl = 'mailto:fadisrour.za3bor@gmail.com';

    return Scaffold(
      appBar: const CustomAppBar(title: 'אודות האפליקציה'),
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
              FutureBuilder<String>(
                future: _checkAppVersion(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'בודק גרסה...', // "Checking version..."
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Text(
                      'שגיאה בקבלת גרסה', // "Error fetching version"
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  } else {
                    return Text(
                      'גרסה: ${snapshot.data}', // Display the version
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                },
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              // LinkedIn link
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
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
                mainAxisAlignment:
                    MainAxisAlignment
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
                      'fadisrour.za3bor@gmail.com', // Email address in Hebrew
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

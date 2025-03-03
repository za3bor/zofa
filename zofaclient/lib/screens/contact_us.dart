import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContactUsScreen extends StatelessWidget {
  ContactUsScreen({super.key});

  // Define URIs for social media and location
  final Uri instagramAppUrl =
      Uri.parse("instagram://user?username=zofahealthshop");
  final Uri instagramWebUrl =
      Uri.parse("https://www.instagram.com/zofahealthshop/");

  final Uri tiktokAppUrl = Uri.parse("tiktok://user?username=zofa.health.shop");
  final Uri tiktokWebUrl =
      Uri.parse("https://www.tiktok.com/@zofa.health.shop");

  final Uri wazeAppUrl = Uri.parse("waze://?ll=32.0853,34.7818&navigate=yes");
  final Uri wazeWebUrl = Uri.parse(
      "https://waze.com/ul?ll=23200072.232000724.577786&navigate=yes");

  final Uri googleMapsAppUrl = Uri.parse("google.navigation:q=32.0853,34.7818");
  final Uri googleMapsWebUrl =
      Uri.parse("https://maps.google.com/?q=32.0853,34.7818");

  // Function to launch URLs
  Future<void> _launchUrl(BuildContext context, Uri appUrl, Uri webUrl) async {
    try {
      // Check if the app URL can be launched
      if (await canLaunchUrl(appUrl)) {
        await launchUrl(appUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web URL if app not available
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Show error message if something goes wrong
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("אירעה שגיאה: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("צור קשר"),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: double
                .infinity, // Ensures the background image fills the whole screen
                width: double.infinity,
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: SingleChildScrollView(
              // Ensures the screen is scrollable
              child: Column(
                children: [
                  // Phone Number Section
                  _buildSectionTitle("מספר טלפון"),
                  SizedBox(height: 8.h),
                  _buildCard(
                    child: GestureDetector(
                      onTap: () => _launchUrl(
                        context,
                        Uri.parse("tel:+123456789"),
                        Uri.parse("tel:+123456789"),
                      ),
                      child: Text(
                        "+123 456 789",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Follow Us Section
                  _buildSectionTitle("עקוב אחרינו"),
                  SizedBox(height: 8.h),
                  _buildCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIconButton(
                          iconUrl:
                              "https://img.icons8.com/ios-glyphs/60/000000/instagram-new.png",
                          onPressed: () => _launchUrl(
                              context, instagramAppUrl, instagramWebUrl),
                        ),
                        _buildIconButton(
                          iconUrl:
                              "https://img.icons8.com/ios-filled/50/000000/tiktok.png",
                          onPressed: () =>
                              _launchUrl(context, tiktokAppUrl, tiktokWebUrl),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Location Section
                  _buildSectionTitle("המיקום שלנו"),
                  SizedBox(height: 8.h),
                  _buildCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIconButton(
                          iconUrl:
                              "https://img.icons8.com/color/48/000000/waze.png",
                          onPressed: () =>
                              _launchUrl(context, wazeAppUrl, wazeWebUrl),
                        ),
                        _buildIconButton(
                          iconUrl:
                              "https://img.icons8.com/ios-filled/50/000000/google-maps.png",
                          onPressed: () => _launchUrl(
                              context, googleMapsAppUrl, googleMapsWebUrl),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Opening Hours Section
                  _buildSectionTitle("שעות פתיחה"),
                  SizedBox(height: 4.h),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: _buildCard(
                      child: Text(
                        "ראשון: סגור\n"
                        "שני - חמישי:\n"
                        "10:00 - 15:00\n"
                        "16:00 - 20:00\n"
                        "שישי - שבת:\n"
                        "20:00 - 10:00",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 16.sp,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 21.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: child,
      ),
    );
  }

  Widget _buildIconButton(
      {required String iconUrl, required VoidCallback onPressed}) {
    return IconButton(
      icon: Image.network(iconUrl),
      iconSize: 40.h,
      onPressed: onPressed,
    );
  }
}

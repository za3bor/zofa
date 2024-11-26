import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        width: 30,
        height: 30,
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
        textDirection: TextDirection.rtl, // Force RTL for all children
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to the right
            children: [
              // App name
              const Text(
                'שם האפליקציה: Zofa Shop', // App name in Hebrew
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right, // Right-align the text
              ),
              const SizedBox(height: 20),

              const Text(
                'גרסה: 3.02.4', // App name in Hebrew
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right, // Right-align the text
              ),
              const SizedBox(height: 20),

              // Developer name
              const Text(
                'מפתח: פאדי סרור', // Developer's name in Hebrew
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right, // Right-align the text
              ),
              const SizedBox(height: 20),

              // Contact section title
              const Text(
                'צור קשר:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right, // Right-align the text
              ),
              const SizedBox(height: 10),

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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _launchURL(linkedinUrl),
                    child: const Text(
                      'פאדי סרור', // LinkedIn name in Hebrew
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.right, // Right-align the text
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _launchURL(emailUrl),
                    child: const Text(
                      'fadisrour.zarbor@gmail.com', // Email address in Hebrew
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.right, // Right-align the text
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

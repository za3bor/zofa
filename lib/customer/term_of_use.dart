import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermOfUseScreen extends StatelessWidget {
  const TermOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    _launchURL();
    return const Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // Show a loading indicator while opening the browser
      ),
    );
  }

  void _launchURL() async {
    final Uri url = Uri.parse(
        'https://www.termsfeed.com/live/6046e72a-93cd-4396-97b3-ae46b2e7f730');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}

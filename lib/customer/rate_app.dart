import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RateAppScreen extends StatelessWidget {
  const RateAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    _launchStore();
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show while opening the store
      ),
    );
  }

  void _launchStore() async {
    final String androidUrl =
        "https://play.google.com/store/apps/details?id=com.zofa_client";
    final String iosUrl = "https://apps.apple.com/app/id6744275359";

    final Uri url = Uri.parse(Platform.isAndroid ? androidUrl : iosUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}

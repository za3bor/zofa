import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareAppScreen extends StatelessWidget {
  const ShareAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    _shareApp(context);
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show while sharing
      ),
    );
  }

  void _shareApp(BuildContext context) async {
    const String androidLink =
        "https://play.google.com/store/apps/details?id=com.zofa_client";
    const String iosLink =
        "https://apps.apple.com/app/id6744275359"; // Replace with real App Store link

    final String appLink = Platform.isAndroid ? androidLink : iosLink;

    await Future.delayed(const Duration(milliseconds: 100)); // Give UI time to render

    try {
      await Share.share(
        "מצאתי אפליקציה מעולה! תוכל להוריד אותה כאן: $appLink",
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("לא ניתן לשתף את האפליקציה.")),
        );
      }
    }
  }
}

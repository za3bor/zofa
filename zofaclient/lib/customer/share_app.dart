import 'package:flutter/material.dart';

class ShareAppScreen extends StatelessWidget {
  const ShareAppScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Text('Settings Page'),
        ),
      ),
    );
  }
}

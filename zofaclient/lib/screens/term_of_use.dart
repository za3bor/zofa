import 'package:flutter/material.dart';

class TermOfUseScreen extends StatelessWidget {
  const TermOfUseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Text('About Page'),
        ),
      ),
    );
  }
}

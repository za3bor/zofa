import 'package:flutter/material.dart';

class RateAppScreen extends StatelessWidget {
  const RateAppScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Text('Notifications Page'),
        ),
      ),
    );
  }
}

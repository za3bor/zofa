import 'dart:math';
import 'package:flutter/material.dart';

class RamadanParticle extends StatefulWidget {
  final double size;
  final Offset offset;
  final double opacity;
  final String assetPath;

  const RamadanParticle({
    super.key,
    required this.size,
    required this.offset,
    required this.opacity,
    required this.assetPath,
  });

  @override
  State<RamadanParticle> createState() => _RamadanParticleState();
}

class _RamadanParticleState extends State<RamadanParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _twinkleController;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      duration: Duration(milliseconds: Random().nextInt(2000) + 1000),
      vsync: this,
      lowerBound: 0.5,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: FadeTransition(
        opacity: _twinkleController,
        child: Image.asset(
          widget.assetPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

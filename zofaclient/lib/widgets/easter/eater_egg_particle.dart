import 'package:flutter/material.dart';
import 'package:zofa_client/widgets/easter/egg_painter.dart';

class EasterEggParticle extends StatefulWidget {
  final double size;
  final Offset offset;
  final double opacity;
  final Color baseColor;
  final List<Color> decorationColors;

  const EasterEggParticle({
    super.key,
    required this.size,
    required this.offset,
    required this.opacity,
    required this.baseColor,
    required this.decorationColors,
  });

  @override
  _EasterEggParticleState createState() => _EasterEggParticleState();
}

class _EasterEggParticleState extends State<EasterEggParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: FadeTransition(
        opacity: AlwaysStoppedAnimation(widget.opacity),
        child: RotationTransition(
          turns: _rotationController,
          child: CustomPaint(
            size: Size(widget.size, widget.size * 1.3),
            painter: EggPainter(
              baseColor: widget.baseColor,
              decorationColors: widget.decorationColors,
            ),
          ),
        ),
      ),
    );
  }
}

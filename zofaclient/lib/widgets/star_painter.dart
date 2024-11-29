// Custom painter to draw a star shape for the snowflakes
import 'package:flutter/material.dart';

class StarPainter extends CustomPainter {
  final double size;
  final Color color;

  StarPainter({required this.size, required this.color});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double centerX = canvasSize.width / 2;
    double centerY = canvasSize.height / 2;

    Path path = Path();

    // Star shape coordinates (based on size)
    path.moveTo(centerX, centerY - size / 2); // Top point
    path.lineTo(centerX + size / 3, centerY + size / 3); // Bottom right
    path.lineTo(centerX - size / 2, centerY - size / 6); // Left point
    path.lineTo(centerX + size / 2, centerY - size / 6); // Right point
    path.lineTo(centerX - size / 3, centerY + size / 3); // Bottom left
    path.close();

    // Draw the star shape on the canvas
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Snowflake particle that will be drawn as a star
class SnowParticle extends StatelessWidget {
  final double size;
  final Offset offset;
  final double opacity;

  const SnowParticle({super.key, required this.size, required this.offset, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size(size, size), // Square size for the star
          painter: StarPainter(
            size: size, // Size of the star
            color: Colors.white, // Star color (white for snowflakes)
          ),
        ),
      ),
    );
  }
}

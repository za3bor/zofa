import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class EggPainter extends CustomPainter {
  final Color baseColor;
  final List<Color> decorationColors;
  final Random random = Random();

  EggPainter({required this.baseColor, required this.decorationColors});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.width, size.height),
        [baseColor.withValues(alpha: 0.9), baseColor.withValues(alpha: 0.6)],
      );

    Rect eggRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawOval(eggRect, paint);

    // Add decorations (stripes, dots, zigzags)
    for (int i = 0; i < decorationColors.length; i++) {
      Paint decoPaint = Paint()..color = decorationColors[i];

      if (random.nextBool()) {
        _drawStripes(canvas, size, decoPaint);
      } else {
        _drawDots(canvas, size, decoPaint);
      }
    }
  }

  void _drawStripes(Canvas canvas, Size size, Paint paint) {
    for (double y = size.height * 0.2;
        y < size.height;
        y += size.height * 0.2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    for (double y = size.height * 0.2;
        y < size.height;
        y += size.height * 0.2) {
      for (double x = size.width * 0.2; x < size.width; x += size.width * 0.3) {
        canvas.drawCircle(Offset(x, y), size.width * 0.05, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

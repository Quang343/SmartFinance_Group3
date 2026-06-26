import 'dart:math' as math;
import 'package:flutter/material.dart';

class FinSmartLogo extends StatelessWidget {
  final double size;
  final Color color;

  const FinSmartLogo({
    super.key,
    this.size = 100,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FinSmartLogoPainter(color: color),
    );
  }
}

class _FinSmartLogoPainter extends CustomPainter {
  final Color color;

  _FinSmartLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double strokeWidth = w * 0.055; // Slightly thinner stroke for elegance

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final pathPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Draw 3 outlined/hollow bars with clear visual gaps
    final double barWidth = w * 0.07;
    final double bottomY = h * 0.85;
    
    final double bar1Height = h * 0.18;
    final double bar2Height = h * 0.30;
    final double bar3Height = h * 0.42;

    // Spread the columns to create a visible gap despite strokeWidth expansion
    final double x1 = w * 0.30;
    final double x2 = w * 0.48;
    final double x3 = w * 0.66;

    // Bar 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x1, bottomY - bar1Height, barWidth, bar1Height),
        Radius.circular(barWidth * 0.35),
      ),
      strokePaint,
    );

    // Bar 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x2, bottomY - bar2Height, barWidth, bar2Height),
        Radius.circular(barWidth * 0.35),
      ),
      strokePaint,
    );

    // Bar 3
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x3, bottomY - bar3Height, barWidth, bar3Height),
        Radius.circular(barWidth * 0.35),
      ),
      strokePaint,
    );

    // 2. Draw rising trend line with arrow (completely floating above the bars)
    final double startX = w * 0.15;
    final double startY = h * 0.58;
    
    final double p1x = w * 0.34;
    final double p1y = h * 0.38;

    final double p2x = w * 0.48;
    final double p2y = h * 0.44;

    final double endX = w * 0.78;
    final double endY = h * 0.18;

    final path = Path()
      ..moveTo(startX, startY)
      ..lineTo(p1x, p1y)
      ..lineTo(p2x, p2y)
      ..lineTo(endX, endY);

    canvas.drawPath(path, pathPaint);

    // 3. Draw arrow head at (endX, endY) aligned with the line's final segment direction
    final double dx = endX - p2x;
    final double dy = endY - p2y;
    final double angle = math.atan2(dy, dx);
    final double arrowLength = w * 0.13;

    canvas.save();
    canvas.translate(endX, endY);
    canvas.rotate(angle);

    // Draw the two barbs of the arrow
    final arrowPath = Path()
      ..moveTo(-arrowLength, -arrowLength * 0.7)
      ..lineTo(0, 0)
      ..lineTo(-arrowLength, arrowLength * 0.7);

    canvas.drawPath(arrowPath, pathPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

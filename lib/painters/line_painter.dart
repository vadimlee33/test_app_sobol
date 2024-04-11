import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:test_app_sobol/utils/utils.dart';

class LinePainter extends CustomPainter {
  final List<Offset> points;
  final Offset cursorPosition;
  final bool isPolygonCompleted;

  LinePainter(this.points, this.cursorPosition, this.isPolygonCompleted);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    if (isPolygonCompleted) {
      canvas.drawLine(points.last, points.first, paint);
    }

    // Проверка на пересечение линий
    bool isIntersecting = false;
    if (points.length > 2) {
      for (var i = 0; i < points.length - 2; i++) {
        if (Utils.doIntersect(
            points[i], points[i + 1], points.last, cursorPosition)) {
          isIntersecting = true;
          break;
        }
      }
    }

    if (isIntersecting) {
      paint.color = Colors.red;
    } else {
      paint.color = Colors.black;
    }
    if (!isPolygonCompleted) {
      canvas.drawLine(points.last, cursorPosition, paint);
    }

    if (isPolygonCompleted) {
      for (var i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        final distance = (p1 - p2).distance;

        if (distance == 0.00) continue;

        final midPoint = Offset.lerp(p1, p2, 0.5)!;
        final textPainter = TextPainter(
          text: TextSpan(
              text: distance.toStringAsFixed(2),
              style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          textDirection: p1.dx < p2.dx ? TextDirection.ltr : TextDirection.rtl,
        );
        textPainter.layout();
        final angle = (p2 - p1).direction;
        final textOffset = midPoint -
            Offset(math.cos(angle + math.pi / 2),
                    math.sin(angle + math.pi / 2)) *
                20;
        canvas.save();
        canvas.translate(textOffset.dx, textOffset.dy);
        canvas.rotate(p1.dx < p2.dx ? angle : angle + math.pi);
        textPainter.paint(
            canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

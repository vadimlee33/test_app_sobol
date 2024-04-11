import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Offset rotate(Offset v, double angle) {
  final cos = math.cos(angle);
  final sin = math.sin(angle);
  return Offset(v.dx * cos - v.dy * sin, v.dx * sin + v.dy * cos);
}

Offset normalize(Offset v) {
  final length = v.distance;
  return Offset(v.dx / length, v.dy / length);
}

int orientation(Offset p, Offset q, Offset r) {
  double val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);

  if (val == 0) return 0; // colinear
  return (val > 0) ? 1 : 2; // clock or counterclock wise
}

bool doIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
  // Find the four orientations needed for general and special cases
  int o1 = orientation(p1, q1, p2);
  int o2 = orientation(p1, q1, q2);
  int o3 = orientation(p2, q2, p1);
  int o4 = orientation(p2, q2, q1);

  // General case
  if (o1 != o2 && o3 != o4) return true;

  // Special Cases
  // p1, q1 and p2 are colinear and p2 lies on segment p1q1
  if (o1 == 0 && onSegment(p1, p2, q1)) return true;

  // p1, q1 and q2 are colinear and q2 lies on segment p1q1
  if (o2 == 0 && onSegment(p1, q2, q1)) return true;

  // p2, q2 and p1 are colinear and p1 lies on segment p2q2
  if (o3 == 0 && onSegment(p2, p1, q2)) return true;

  // p2, q2 and q1 are colinear and q1 lies on segment p2q2
  if (o4 == 0 && onSegment(p2, q1, q2)) return true;

  return false; // Doesn't fall in any of the above cases
}

bool onSegment(Offset p, Offset q, Offset r) {
  if (q.dx <= math.max(p.dx, r.dx) &&
      q.dx >= math.min(p.dx, r.dx) &&
      q.dy <= math.max(p.dy, r.dy) &&
      q.dy >= math.min(p.dy, r.dy)) return true;

  return false;
}

final isIntersectingController = StateController<bool>(false);

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
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw the existing lines
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw the line from the last point to the first point if the polygon is completed
    if (isPolygonCompleted) {
      canvas.drawLine(points.last, points.first, paint);
    }

    // Check for line intersections
    bool isIntersecting = false;
    if (points.length > 2) {
      for (var i = 0; i < points.length - 2; i++) {
        if (doIntersect(
            points[i], points[i + 1], points.last, cursorPosition)) {
          isIntersecting = true;
          break;
        }
      }
    }

    // Change the color of the paint if the current line intersects
    if (isIntersecting) {
      paint.color = Colors.red;
    } else {
      paint.color = Colors.black;
    }

    // Draw the current line
    if (!isPolygonCompleted) {
      canvas.drawLine(points.last, cursorPosition, paint);
    }

    if (isPolygonCompleted) {
      for (var i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        final distance = (p1 - p2).distance;

        // Skip if the line length is 0.00
        if (distance == 0.00) continue;

        final midPoint = Offset.lerp(p1, p2, 0.5)!;
        final textPainter = TextPainter(
          text: TextSpan(
              text: distance.toStringAsFixed(2),
              style: TextStyle(color: Colors.black, fontSize: 16)),
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

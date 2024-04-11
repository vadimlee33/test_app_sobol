import 'package:flutter/material.dart';
import 'dart:math' as math;

class Utils {
  static Offset snapToGrid(Offset point) {
    const double step = 20.0;
    return Offset(
      (point.dx / step).round() * step,
      (point.dy / step).round() * step,
    );
  }

  static bool doIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && onSegment(p1, p2, q1)) return true;

    if (o2 == 0 && onSegment(p1, q2, q1)) return true;

    if (o3 == 0 && onSegment(p2, p1, q2)) return true;

    if (o4 == 0 && onSegment(p2, q1, q2)) return true;

    return false;
  }

  static Offset rotate(Offset v, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(v.dx * cos - v.dy * sin, v.dx * sin + v.dy * cos);
  }

  static Offset normalize(Offset v) {
    final length = v.distance;
    return Offset(v.dx / length, v.dy / length);
  }

  static int orientation(Offset p, Offset q, Offset r) {
    double val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);

    if (val == 0) return 0;
    return (val > 0) ? 1 : 2;
  }

  static bool onSegment(Offset p, Offset q, Offset r) {
    if (q.dx <= math.max(p.dx, r.dx) &&
        q.dx >= math.min(p.dx, r.dx) &&
        q.dy <= math.max(p.dy, r.dy) &&
        q.dy >= math.min(p.dy, r.dy)) return true;

    return false;
  }
}

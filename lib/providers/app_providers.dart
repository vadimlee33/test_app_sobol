import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppProviders {
  static final cursorPositionProvider = StateProvider<Offset>((ref) => Offset.infinite);
  static final pointsProvider = StateProvider<List<Offset>>((ref) => []);
  static final undoStackProvider = StateProvider<List<List<Offset>>>((ref) => []);
  static final redoStackProvider = StateProvider<List<List<Offset>>>((ref) => []);
  static final isPolygonCompletedProvider = StateProvider<bool>((ref) => false);
  static final isIntersectingProvider = StateProvider<bool>((ref) => false);
  static final isSnapToGridEnabledProvider = StateProvider<bool>((ref) => false);
}
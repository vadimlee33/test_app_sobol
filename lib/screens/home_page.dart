import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_app_sobol/widgets/cursor_widget.dart';
import 'package:test_app_sobol/widgets/grid_painter.dart';
import 'package:test_app_sobol/widgets/line_painter.dart';

class HomePage extends ConsumerWidget {
  final TransformationController _transformationController =
      TransformationController();

  final cursorPositionProvider =
      StateProvider<Offset>((ref) => Offset.infinite);
  final pointsProvider = StateProvider<List<Offset>>((ref) => []);
  final undoStackProvider = StateProvider<List<List<Offset>>>((ref) => []);
  final redoStackProvider = StateProvider<List<List<Offset>>>((ref) => []);
  final isPolygonCompletedProvider = StateProvider<bool>((ref) => false);
  final isIntersectingProvider = StateProvider<bool>((ref) => false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursorPosition = ref.watch(cursorPositionProvider);
    final points = ref.watch(pointsProvider);
    final undoStack = ref.watch(undoStackProvider);
    final redoStack = ref.watch(redoStackProvider);
    bool isPolygonCompleted = ref.watch(isPolygonCompletedProvider);
    final isIntersecting = ref.watch(isIntersectingProvider);
    return Scaffold(
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.1,
        maxScale: 2.0,
        child: GestureDetector(
          onPanUpdate: (details) {
            if (!isPolygonCompleted) {
              ref.read(cursorPositionProvider.notifier).state =
                  details.localPosition;
              if (points.length > 1 &&
                  (points.first - details.localPosition).distance < 10.0) {
                ref.read(isPolygonCompletedProvider.notifier).state = true;
              }
            }
          },
          onTap: () {
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

            if (isIntersecting) {
              print("Intersecting lines!");
              return;
            } else {
              if (!isPolygonCompleted &&
                  cursorPosition.isFinite &&
                  (points.isEmpty ||
                      (points.last - cursorPosition).distance > 0.0)) {
                print("Tapped point: $cursorPosition");
                ref.read(undoStackProvider.notifier).state =
                    List.from(undoStack)..add(List.from(points));
                ref.read(redoStackProvider.notifier).state = [];
                if (!(points.length > 1 &&
                    (points.first - cursorPosition).distance < 10.0)) {
                  ref.read(pointsProvider.notifier).state = List.from(points)
                    ..add(cursorPosition);
                } else {
                  isPolygonCompleted = true;
                }
                ref.read(cursorPositionProvider.notifier).state =
                    cursorPosition;
              }
            }
          },
          child: Stack(
            children: [
              CustomPaint(
                painter: GridPainter(),
                child: Container(),
              ),

              CustomPaint(
                painter: LinePainter(
                  points,
                  cursorPosition.isFinite ? cursorPosition : Offset.zero,
                  isPolygonCompleted,
                ),
                child: Container(),
              ),
              // отображение зафиксированных точек
              for (var i = 0; i < points.length; i++)
                CursorWidget(
                  position: points[i],
                  color: Colors.red,
                  iconSize: 20,
                  onPanUpdate: (details) {
                    final scale =
                        _transformationController.value.getMaxScaleOnAxis();
                    final newPoints = List<Offset>.from(points);
                    newPoints[i] = newPoints[i] + details.delta / scale;
                    ref.read(pointsProvider.notifier).state = newPoints;
                  },
                  icon: Icons.circle, // иконка для зафиксированной точки
                ),
              // отображение курсора
              if (cursorPosition.isFinite && !isPolygonCompleted)
                CursorWidget(
                  position: cursorPosition,
                  iconSize: 40.0,
                  color: points.isEmpty ? Colors.blue : Colors.green,
                  onPanUpdate: (_) {},
                  icon: Icons.gps_fixed, // иконка для курсора
                ),
              Positioned(
                top: 30,
                left: 10,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.undo),
                      color: Colors.black,
                      iconSize: 32,
                      onPressed: undoStack.isEmpty
                          ? null
                          : () {
                              ref.read(redoStackProvider.notifier).state =
                                  List.from(redoStack)..add(List.from(points));
                              ref.read(pointsProvider.notifier).state =
                                  undoStack.removeLast();
                              ref
                                  .read(isPolygonCompletedProvider.notifier)
                                  .state = false;
                            },
                    ),
                    IconButton(
                      icon: Icon(Icons.redo),
                      color: Colors.black,
                      iconSize: 32,
                      onPressed: redoStack.isEmpty
                          ? null
                          : () {
                              ref.read(undoStackProvider.notifier).state =
                                  List.from(undoStack)..add(List.from(points));
                              ref.read(pointsProvider.notifier).state =
                                  redoStack.removeLast();
                              ref
                                  .read(isPolygonCompletedProvider.notifier)
                                  .state = false;
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

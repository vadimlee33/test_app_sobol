import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_app_sobol/providers/app_providers.dart';
import 'package:test_app_sobol/utils/utils.dart';
import 'package:test_app_sobol/widgets/cursor_widget.dart';
import 'package:test_app_sobol/widgets/grid_painter.dart';
import 'package:test_app_sobol/widgets/line_painter.dart';

class HomePage extends ConsumerWidget {
  final TransformationController _transformationController =
      TransformationController();

  HomePage({super.key});

  void handleTap(BuildContext context, WidgetRef ref) {
    final cursorPosition = ref.read(AppProviders.cursorPositionProvider);
    final points = ref.read(AppProviders.pointsProvider);
    final isPolygonCompleted =
        ref.read(AppProviders.isPolygonCompletedProvider);
    final isSnapToGridEnabled =
        ref.read(AppProviders.isSnapToGridEnabledProvider);

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

    if (!isIntersecting) {
      if (!isPolygonCompleted &&
          cursorPosition.isFinite &&
          (points.isEmpty || (points.last - cursorPosition).distance > 0.0)) {
        ref.read(AppProviders.undoStackProvider.notifier).state =
            List.from(ref.read(AppProviders.undoStackProvider))
              ..add(List.from(points));
        ref.read(AppProviders.redoStackProvider.notifier).state = [];
        if (!(points.length > 1 &&
            (points.first - cursorPosition).distance < 10.0)) {
          ref.read(AppProviders.pointsProvider.notifier).state =
              List.from(points)
                ..add(isSnapToGridEnabled
                    ? Utils.snapToGrid(cursorPosition)
                    : cursorPosition);
        } else {
          ref.read(AppProviders.isPolygonCompletedProvider.notifier).state =
              true;
        }
        ref.read(AppProviders.cursorPositionProvider.notifier).state =
            cursorPosition;
      }
    }
  }

  void handleUndoRedo(BuildContext context, WidgetRef ref, bool isUndo) {
    final points = ref.read(AppProviders.pointsProvider);
    final undoStack = ref.read(AppProviders.undoStackProvider);
    final redoStack = ref.read(AppProviders.redoStackProvider);

    if (isUndo ? undoStack.isEmpty : redoStack.isEmpty) return;

    ref
        .read(isUndo
            ? AppProviders.redoStackProvider.notifier
            : AppProviders.undoStackProvider.notifier)
        .state = List.from(isUndo ? undoStack : redoStack)
      ..add(List.from(points));
    ref.read(AppProviders.pointsProvider.notifier).state =
        isUndo ? undoStack.removeLast() : redoStack.removeLast();
    ref.read(AppProviders.isPolygonCompletedProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursorPosition = ref.watch(AppProviders.cursorPositionProvider);
    final points = ref.watch(AppProviders.pointsProvider);
    final undoStack = ref.watch(AppProviders.undoStackProvider);
    final redoStack = ref.watch(AppProviders.redoStackProvider);
    final isPolygonCompleted =
        ref.watch(AppProviders.isPolygonCompletedProvider);
    final isSnapToGridEnabled =
        ref.watch(AppProviders.isSnapToGridEnabledProvider);

    return Scaffold(
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.1,
        maxScale: 2.0,
        child: GestureDetector(
          onPanUpdate: (details) {
            if (!isPolygonCompleted) {
              ref.read(AppProviders.cursorPositionProvider.notifier).state =
                  isSnapToGridEnabled
                      ? Utils.snapToGrid(details.localPosition)
                      : details.localPosition;
              if (points.length > 1 &&
                  (points.first - details.localPosition).distance < 10.0) {
                ref
                    .read(AppProviders.isPolygonCompletedProvider.notifier)
                    .state = true;
              }
            }
          },
          onTap: () => handleTap(context, ref),
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
              for (var i = 0; i < points.length; i++)
                CursorWidget(
                  position: points[i],
                  color: Colors.blue,
                  iconSize: 20,
                  onPanUpdate: (details) {
                    final scale =
                        _transformationController.value.getMaxScaleOnAxis();
                    final newPoints = List<Offset>.from(points);
                    newPoints[i] = isSnapToGridEnabled
                        ? Utils.snapToGrid(newPoints[i] + details.delta / scale)
                        : newPoints[i] + details.delta / scale;
                    ref.read(AppProviders.pointsProvider.notifier).state =
                        newPoints;
                  },
                  icon: Icons.circle,
                ),
              if (cursorPosition.isFinite && !isPolygonCompleted)
                CursorWidget(
                  position: cursorPosition,
                  iconSize: 40.0,
                  color: points.isEmpty ? Colors.blue : Colors.green,
                  onPanUpdate: (_) {},
                  icon: Icons.gps_fixed,
                ),
              Positioned(
                top: 30,
                left: 10,
                child: SizedBox(
                    width: MediaQuery.of(context).size.width - 20,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.undo),
                          color: undoStack.isEmpty ? Colors.grey : Colors.black,
                          iconSize: 32,
                          onPressed: undoStack.isEmpty
                              ? null
                              : () => handleUndoRedo(context, ref, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.redo),
                          color: redoStack.isEmpty ? Colors.grey : Colors.black,
                          iconSize: 32,
                          onPressed: redoStack.isEmpty
                              ? null
                              : () => handleUndoRedo(context, ref, false),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(isSnapToGridEnabled
                              ? Icons.grid_on
                              : Icons.grid_off),
                          color: Colors.black,
                          iconSize: 32,
                          onPressed: () {
                            ref
                                .read(AppProviders
                                    .isSnapToGridEnabledProvider.notifier)
                                .state = !isSnapToGridEnabled;
                            if (isSnapToGridEnabled) {
                              final newPoints = List<Offset>.from(points);
                              for (var i = 0; i < newPoints.length; i++) {
                                newPoints[i] = Utils.snapToGrid(newPoints[i]);
                              }
                              ref
                                  .read(AppProviders.pointsProvider.notifier)
                                  .state = newPoints;
                            }
                          },
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

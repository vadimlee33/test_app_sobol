import 'package:flutter/material.dart';

class CursorWidget extends StatelessWidget {
  final Offset position;
  final Color color;
  final Function(DragUpdateDetails) onPanUpdate;
  final IconData icon;
  final double iconSize;

  const CursorWidget(
      {super.key,
      required this.position,
      required this.color,
      required this.onPanUpdate,
      required this.iconSize,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - iconSize / 2,
      top: position.dy - iconSize / 2,
      child: GestureDetector(
        onPanDown: (details) {
          onPanUpdate(DragUpdateDetails(
            globalPosition: details.globalPosition,
            delta: Offset.zero,
            localPosition: details.localPosition,
            primaryDelta: null,
            sourceTimeStamp: null,
          ));
        },
        onPanUpdate: onPanUpdate,
        child: Icon(
          icon,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}

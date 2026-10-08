import 'package:flutter/material.dart';

/// Builds the magnifier for [line]: the caret's line at the selection edge
/// being dragged (zero-width at the caret), or the finger's point when the
/// drag is on the text itself. In the editor's local coordinates.
typedef QuillMagnifierBuilder = Widget Function(Rect line);

Widget defaultQuillMagnifierBuilder(Rect line) =>
    QuillMagnifier(dragPosition: line.center);

class QuillMagnifier extends StatelessWidget {
  const QuillMagnifier({required this.dragPosition, super.key});

  final Offset dragPosition;

  @override
  Widget build(BuildContext context) {
    final position = dragPosition.translate(-60, -80);
    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: RawMagnifier(
          clipBehavior: Clip.hardEdge,
          decoration: MagnifierDecoration(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            shadows: const [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(3, 3), // changes position of shadow
              ),
            ],
          ),
          size: const Size(100, 45),
          focalPointOffset: const Offset(5, 55),
          magnificationScale: 1.3,
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

class Vehicle3DViewer extends StatefulWidget {
  final List<String> photoPaths;
  final double radius;

  const Vehicle3DViewer({
    super.key,
    this.photoPaths = const [],
    this.radius = 160, // Reduced radius for smaller dashboard footprint
  });

  @override
  State<Vehicle3DViewer> createState() => _Vehicle3DViewerState();
}

class _Vehicle3DViewerState extends State<Vehicle3DViewer> {
  double _rotationDeg = 0;
  double _velocity = 0;
  double _dragStartX = 0;
  double _rotationAtDragStart = 0;

  int get _panelCount => widget.photoPaths.isEmpty ? 8 : widget.photoPaths.length;
  double get _angleStep => 360 / _panelCount;

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _rotationAtDragStart = _rotationDeg;
    _velocity = 0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dx = details.globalPosition.dx - _dragStartX;
    setState(() {
      _rotationDeg = _rotationAtDragStart + dx * 0.6;
      _velocity = details.delta.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    var v = _velocity * 4;
    void coast() {
      if (v.abs() < 2) return;
      if (!mounted) return;
      setState(() => _rotationDeg += v * 0.016);
      v *= 0.94;
      Future.delayed(const Duration(milliseconds: 16), coast);
    }
    coast();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedAngle = ((_rotationDeg % 360) + 360) % 360;

    return Center( // Ensure it's centered and doesn't bleed out
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 1.5,
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                behavior: HitTestBehavior.opaque, // Better drag capture
                child: SizedBox(
                  width: widget.radius * 1.5,
                  height: widget.radius * 1.5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(_panelCount, (i) {
                      final panelAngleDeg = i * _angleStep;
                      final relativeRad = (panelAngleDeg - _rotationDeg) * math.pi / 180;
                      final facingCamera = math.cos(relativeRad) > -0.15;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0016)
                          ..rotateY(panelAngleDeg * math.pi / 180)
                          // ignore: deprecated_member_use
                          ..translate(0.0, 0.0, widget.radius * 0.8)
                          ..rotateY(-panelAngleDeg * math.pi / 180),
                        child: Opacity(
                          opacity: facingCamera ? 1 : 0,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(_rotationDeg * math.pi / 180),
                            child: _buildPanel(i),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Text(
                '${normalizedAngle.round()}° - DRAG TO ROTATE',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(int index) {
    final size = widget.radius * 1.2;
    if (widget.photoPaths.isNotEmpty) {
      return Image.asset(
        widget.photoPaths[index],
        width: size,
        fit: BoxFit.contain,
      );
    }
    return SizedBox(
      width: size,
      height: size * 0.5,
      child: CustomPaint(painter: _CarSilhouettePainter()),
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFC7CCD1).withOpacity(0.3);
    final glass = Paint()..color = const Color(0xFF3A4650).withOpacity(0.3);
    final wheel = Paint()..color = const Color(0xFF101113).withOpacity(0.3);

    final path = Path()
      ..moveTo(size.width * 0.09, size.height * 0.66)
      ..cubicTo(size.width * 0.09, size.height * 0.5, size.width * 0.17, size.height * 0.44, size.width * 0.24, size.height * 0.42)
      ..lineTo(size.width * 0.32, size.height * 0.24)
      ..cubicTo(size.width * 0.35, size.height * 0.16, size.width * 0.41, size.height * 0.13, size.width * 0.5, size.height * 0.13)
      ..cubicTo(size.width * 0.59, size.height * 0.13, size.width * 0.65, size.height * 0.16, size.width * 0.68, size.height * 0.24)
      ..lineTo(size.width * 0.76, size.height * 0.42)
      ..cubicTo(size.width * 0.83, size.height * 0.44, size.width * 0.91, size.height * 0.5, size.width * 0.91, size.height * 0.66)
      ..close();

    canvas.drawPath(path, body);
    canvas.drawCircle(Offset(size.width * 0.26, size.height * 0.78), size.width * 0.06, wheel);
    canvas.drawCircle(Offset(size.width * 0.74, size.height * 0.78), size.width * 0.06, wheel);

    final glassPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.4)
      ..lineTo(size.width * 0.41, size.height * 0.25)
      ..lineTo(size.width * 0.59, size.height * 0.25)
      ..lineTo(size.width * 0.65, size.height * 0.4)
      ..close();
    canvas.drawPath(glassPath, glass);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

class Vehicle3DViewer extends StatefulWidget {
  /// Rutas de las fotos del vehículo, en orden angular (0°, 360/N°, ...).
  /// Si viene vacío, se muestra una silueta de reemplazo por ángulo.
  final List<String> photoPaths;

  /// Radio del cilindro virtual sobre el que se colocan las fotos.
  final double radius;

  const Vehicle3DViewer({
    super.key,
    this.photoPaths = const [],
    this.radius = 220,
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
    // Pequeña inercia al soltar, luego se detiene.
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF131417), Color(0xFF0B0C0E)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 14,
              child: Text(
                '${normalizedAngle.round()}°',
                style: const TextStyle(
                  color: Color(0xFF5EC8E0),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: SizedBox(
                  width: widget.radius * 1.7,
                  height: widget.radius * 1.7,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(_panelCount, (i) {
                      final panelAngleDeg = i * _angleStep;
                      // ángulo relativo a la cámara: qué tan de frente
                      // está este panel respecto al giro actual
                      final relativeRad =
                          (panelAngleDeg - _rotationDeg) * math.pi / 180;

                      // Solo se muestran los paneles que miran hacia la
                      // cámara (evita solapamientos raros del resto).
                      final facingCamera = math.cos(relativeRad) > -0.15;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0016)
                          ..rotateY(panelAngleDeg * math.pi / 180)
                          ..translate(0.0, 0.0, widget.radius.toDouble())
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
            const Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Text(
                'ARRASTRA PARA GIRAR EL VEHÍCULO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8B9096),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(int index) {
    final size = widget.radius * 1.4;
    if (widget.photoPaths.isNotEmpty) {
      return Image.asset(
        widget.photoPaths[index],
        width: size,
        fit: BoxFit.contain,
      );
    }
    // Silueta de reemplazo mientras no hay fotos reales cargadas.
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
    final body = Paint()..color = const Color(0xFFC7CCD1);
    final glass = Paint()..color = const Color(0xFF3A4650);
    final wheel = Paint()..color = const Color(0xFF101113);

    final path = Path()
      ..moveTo(size.width * 0.09, size.height * 0.66)
      ..cubicTo(
        size.width * 0.09, size.height * 0.5,
        size.width * 0.17, size.height * 0.44,
        size.width * 0.24, size.height * 0.42,
      )
      ..lineTo(size.width * 0.32, size.height * 0.24)
      ..cubicTo(
        size.width * 0.35, size.height * 0.16,
        size.width * 0.41, size.height * 0.13,
        size.width * 0.5, size.height * 0.13,
      )
      ..cubicTo(
        size.width * 0.59, size.height * 0.13,
        size.width * 0.65, size.height * 0.16,
        size.width * 0.68, size.height * 0.24,
      )
      ..lineTo(size.width * 0.76, size.height * 0.42)
      ..cubicTo(
        size.width * 0.83, size.height * 0.44,
        size.width * 0.91, size.height * 0.5,
        size.width * 0.91, size.height * 0.66,
      )
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

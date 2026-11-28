import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RealisticVehicleBody extends StatefulWidget {
  const RealisticVehicleBody({
    super.key,
    required this.shape,
    required this.color,
    required this.lighting,
    required this.hoodOpen,
    this.lowResource = false,
  });
  final String shape;
  final Color color;
  final double lighting;
  final bool hoodOpen, lowResource;
  @override
  State<RealisticVehicleBody> createState() => _RealisticVehicleBodyState();
}

class _RealisticVehicleBodyState extends State<RealisticVehicleBody> {
  static ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener;
  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener((image, _) {
      if (!mounted) return;
      final old = _image;
      setState(() => _image = image.clone());
      old?.dispose();
    });
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      final program = _program ??= await ui.FragmentProgram.fromAsset(
        'shaders/vehicle_paint.frag',
      );
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (error) {
      debugPrint('Vehicle paint shader unavailable: $error');
    }
  }

  void _load() {
    _stream?.removeListener(_listener);
    _stream = ResizeImage(
      AssetImage('assets/vehicles/top/${widget.shape}.png'),
      width: widget.lowResource ? 320 : 512,
    ).resolve(createLocalImageConfiguration(context));
    _stream!.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(covariant RealisticVehicleBody old) {
    super.didUpdateWidget(old);
    if (old.shape != widget.shape || old.lowResource != widget.lowResource)
      _load();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    child: const SizedBox.expand(),
    painter: _VehicleArtwork(
      _image?.image,
      _shader,
      widget.color,
      widget.lighting,
      widget.hoodOpen,
      widget.shape,
    ),
  );
}

class _VehicleArtwork extends CustomPainter {
  const _VehicleArtwork(
    this.image,
    this.shader,
    this.color,
    this.lighting,
    this.hoodOpen,
    this.shape,
  );
  final ui.Image? image;
  final ui.FragmentShader? shader;
  final Color color;
  final double lighting;
  final bool hoodOpen;
  final String shape;
  @override
  void paint(Canvas canvas, Size size) {
    final source = image;
    if (source == null || size.isEmpty) return;
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(source.width.toDouble(), source.height.toDouble()),
      Size(size.width * .94, size.height * .86),
    );
    final rect = Alignment.center
        .inscribe(fitted.destination, Offset.zero & size)
        .translate(0, size.height * .025);
    canvas.save();
    canvas.translate(rect.left, rect.top);
    final w = rect.width, h = rect.height;
    final effect = shader;
    if (effect != null) {
      effect
        ..setFloat(0, w)
        ..setFloat(1, h)
        ..setFloat(2, color.r)
        ..setFloat(3, color.g)
        ..setFloat(4, color.b)
        ..setFloat(5, lighting)
        ..setImageSampler(0, source);
      canvas.drawRect(
        Rect.fromLTRB(-w * .2, -h * .32, w * 1.2, h * 1.12),
        Paint()..shader = effect,
      );
    } else {
      canvas.drawImageRect(
        source,
        Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
        Rect.fromLTWH(0, 0, w, h),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    if (hoodOpen) _engine(canvas, w, h);
    if (lighting > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final side in [-1.0, 1.0]) {
        final head = Path()
          ..moveTo(w * (.5 + side * .24), h * .082)
          ..quadraticBezierTo(
            w * (.5 + side * .31),
            h * .105,
            w * (.5 + side * .34),
            h * .15,
          );
        paint
          ..color = Color.fromRGBO(205, 235, 255, .12 * lighting)
          ..strokeWidth = w * .045;
        canvas.drawPath(head, paint);
        canvas.drawPath(
          head,
          paint
            ..color = Color.fromRGBO(237, 249, 255, .92 * lighting)
            ..strokeWidth = w * .006,
        );
        final tail = Path()
          ..moveTo(w * (.5 + side * .14), h * .88)
          ..quadraticBezierTo(
            w * (.5 + side * .27),
            h * .875,
            w * (.5 + side * .32),
            h * .848,
          );
        canvas.drawPath(
          tail,
          paint
            ..color = Color.fromRGBO(255, 48, 28, .16 * lighting)
            ..strokeWidth = w * .04,
        );
        canvas.drawPath(
          tail,
          paint
            ..color = Color.fromRGBO(255, 69, 42, .94 * lighting)
            ..strokeWidth = w * .009,
        );
      }
    }
    canvas.restore();
  }

  void _engine(Canvas canvas, double w, double h) {
    final bay = Path()
      ..moveTo(w * .28, h * .13)
      ..quadraticBezierTo(w * .5, h * .10, w * .72, h * .13)
      ..lineTo(w * .76, h * .245)
      ..quadraticBezierTo(w * .5, h * .225, w * .24, h * .245)
      ..close();
    final bounds = Rect.fromLTRB(w * .24, h * .12, w * .76, h * .245);
    canvas.drawPath(
      bay,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF04090F), Color(0xFF20303A), Color(0xFF080C13)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      bay,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .006
        ..color = const Color(0xFF8796A2),
    );
    final block = Rect.fromCenter(
      center: Offset(w * .5, h * .18),
      width: w * .24,
      height: h * .075,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(block, Radius.circular(w * .02)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF71818B), Color(0xFF283A47), Color(0xFF4D5F6B)],
        ).createShader(block),
    );
    final paint = Paint()
      ..color = const Color(0xFF99A9B0)
      ..strokeWidth = w * .004;
    for (var i = 0; i < 5; i++)
      canvas.drawLine(
        Offset(block.left + w * .03, block.top + h * (.012 + i * .01)),
        Offset(block.right - w * .03, block.top + h * (.012 + i * .01)),
        paint,
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .27, h * .145, w * .09, h * .046),
        Radius.circular(w * .008),
      ),
      Paint()..color = const Color(0xFF121D29),
    );
    canvas.drawCircle(
      Offset(w * .29, h * .151),
      w * .009,
      Paint()..color = const Color(0xFFDC5249),
    );
    canvas.drawCircle(
      Offset(w * .69, h * .151),
      w * .013,
      Paint()..color = const Color(0xFFECB85E),
    );
  }

  @override
  bool shouldRepaint(covariant _VehicleArtwork old) =>
      old.image != image ||
      old.shader != shader ||
      old.color != color ||
      old.lighting != lighting ||
      old.hoodOpen != hoodOpen ||
      old.shape != shape;
}

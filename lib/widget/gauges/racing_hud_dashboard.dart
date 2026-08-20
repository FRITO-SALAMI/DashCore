import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/obd_provider.dart';
import '../../providers/dash_settings_provider.dart';

/// DashCore — Racing / Space HUD
///
/// Diseño inspirado en el cluster de referencia:
/// - Fondo negro profundo.
/// - Rojo neón como color de acento.
/// - Velocímetro semicircular dominante.
/// - Vehículo central con sensores.
/// - Panel de información lateral.
/// - Datos reales provenientes de ObdProvider.
class RacingHudDashboard extends StatelessWidget {
  const RacingHudDashboard({super.key});

  static const Color _background = Color(0xFF020304);
  static const Color _surface = Color(0xFF080B0D);
  static const Color _surface2 = Color(0xFF0C1012);

  static const Color _red = Color(0xFFFF2638);
  static const Color _white = Color(0xFFF2F4F5);
  static const Color _muted = Color(0xFF697378);

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<ObdProvider>();
    final settings = context.watch<DashSettingsProvider>();

    final data = obd.data;
    final isConnected = obd.isDeviceConnected;

    final speed = data.speed.toDouble();
    final rpm = data.rpm.toDouble();
    final coolant = settings.convertTemp(data.engineTemp);
    final voltage = data.voltage;
    
    final speedUnit = settings.language == Language.english ? 'mph' : 'km/h'; // Simplified logic for demo

    return Container(
      color: _background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const _Background(),

              _TopStatus(
                connected: isConnected,
              ),

              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth * .025,
                    constraints.maxHeight * .075,
                    constraints.maxWidth * .025,
                    constraints.maxHeight * .035,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 60,
                        child: _MainCluster(
                          speed: speed,
                          speedUnit: speedUnit,
                          fuelPercent: 60,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth * .025,
                      ),
                      Expanded(
                        flex: 32,
                        child: _InfoPanel(
                          coolant: coolant,
                          voltage: voltage,
                          rpm: rpm,
                          connected: isConnected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const _Vignette(),
            ],
          );
        },
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, 1.2),
        radius: 1.15,
        colors: [
          Color(0xFF160408),
          Color(0xFF07090A),
          Color(0xFF020304),
        ],
        stops: [0, .42, 1],
      ).createShader(rect);

    canvas.drawRect(rect, background);

    final horizonGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1),
        radius: .75,
        colors: [
          RacingHudDashboard._red.withValues(alpha: .18),
          RacingHudDashboard._red.withValues(alpha: .055),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height),
          radius: size.width * .65,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width / 2,
          size.height * 1.02,
        ),
        width: size.width * 1.15,
        height: size.height * .45,
      ),
      horizonGlow,
    );

    final horizon = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0x00FF2638),
          Color(0x99FF2638),
          Color(0x00FF2638),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          size.height * .91,
          size.width,
          2,
        ),
      )
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width * .15, size.height * .91),
      Offset(size.width * .85, size.height * .91),
      horizon,
    );

    final starPaint = Paint();
    final random = math.Random(42);

    for (var i = 0; i < 85; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * .86;
      final radius = .25 + random.nextDouble() * .65;

      starPaint.color = Colors.white.withValues(
        alpha: .08 + random.nextDouble() * .28,
      );

      canvas.drawCircle(
        Offset(x, y),
        radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopStatus extends StatelessWidget {
  const _TopStatus({
    required this.connected,
  });

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'DASH',
                style: TextStyle(
                  color: RacingHudDashboard._white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'CORE',
                style: TextStyle(
                  color: RacingHudDashboard._red,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  shadows: const [
                    Shadow(
                      color: RacingHudDashboard._red,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: connected
                      ? RacingHudDashboard._red
                      : Colors.white24,
                  shape: BoxShape.circle,
                  boxShadow: connected
                      ? const [
                          BoxShadow(
                            color: RacingHudDashboard._red,
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                connected ? 'OBD CONNECTED' : 'NO SIGNAL',
                style: const TextStyle(
                  color: RacingHudDashboard._muted,
                  fontSize: 8,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainCluster extends StatelessWidget {
  const _MainCluster({
    required this.speed,
    required this.speedUnit,
    required this.fuelPercent,
  });

  final double speed;
  final String speedUnit;
  final int fuelPercent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: RacingHudDashboard._surface.withValues(alpha: .56),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                constraints.maxWidth * .16,
              ),
              topRight: Radius.circular(
                constraints.maxWidth * .12,
              ),
              bottomLeft: Radius.circular(
                constraints.maxWidth * .14,
              ),
              bottomRight: Radius.circular(
                constraints.maxWidth * .18,
              ),
            ),
            border: Border.all(
              color: RacingHudDashboard._red.withValues(
                alpha: .27,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: RacingHudDashboard._red.withValues(
                  alpha: .055,
                ),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _ClusterBorderPainter(),
              ),

              Positioned(
                top: constraints.maxHeight * .035,
                left: constraints.maxWidth * .05,
                right: constraints.maxWidth * .05,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const _SmallLabel(
                      icon: Icons.navigation_outlined,
                      text: 'PERFORMANCE',
                    ),
                    _SmallLabel(
                      icon: Icons.speed,
                      text:
                          speedUnit.toUpperCase(),
                    ),
                  ],
                ),
              ),

              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: constraints.maxHeight * .08,
                  ),
                  child: CustomPaint(
                    painter: _SpeedGaugePainter(
                      speed: speed,
                      maxSpeed: speedUnit == 'mph'
                          ? 160
                          : 240,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: constraints.maxHeight * .30,
                          left: 0,
                          right: 0,
                          child: _SpeedNumber(
                            speed: speed,
                            unit: speedUnit,
                          ),
                        ),

                        Positioned(
                          top: constraints.maxHeight * .54,
                          left: constraints.maxWidth * .25,
                          right: constraints.maxWidth * .25,
                          child: _VehicleGraphic(),
                        ),

                        Positioned(
                          bottom: constraints.maxHeight * .075,
                          left: constraints.maxWidth * .28,
                          right: constraints.maxWidth * .28,
                          child: _FuelIndicator(
                            percent: fuelPercent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClusterBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RacingHudDashboard._red.withValues(
        alpha: .18,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    path.moveTo(size.width * .08, 0);
    path.lineTo(size.width * .27, 0);
    path.moveTo(size.width * .73, 0);
    path.lineTo(size.width * .91, 0);
    path.moveTo(0, size.height * .78);
    path.lineTo(0, size.height * .60);
    path.moveTo(size.width, size.height * .25);
    path.lineTo(size.width, size.height * .42);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 11,
          color: RacingHudDashboard._red,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: RacingHudDashboard._muted,
            fontSize: 7,
            letterSpacing: 1.7,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SpeedNumber extends StatelessWidget {
  const _SpeedNumber({
    required this.speed,
    required this.unit,
  });

  final double speed;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          speed.round().toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: RacingHudDashboard._white,
            fontSize: 64,
            height: .85,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            fontFeatures: [
              FontFeature.tabularFigures(),
            ],
            shadows: [
              Shadow(
                color: Colors.white24,
                blurRadius: 8,
              ),
              Shadow(
                color: RacingHudDashboard._red,
                blurRadius: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          unit.toUpperCase(),
          style: const TextStyle(
            color: RacingHudDashboard._red,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: RacingHudDashboard._red,
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  const _SpeedGaugePainter({
    required this.speed,
    required this.maxSpeed,
  });

  final double speed;
  final double maxSpeed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height * .43,
    );

    final radius =
        math.min(size.width * .39, size.height * .38);

    const startAngle = math.pi * 1.13;
    const sweepAngle = math.pi * .74;

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = RacingHudDashboard._red.withValues(
        alpha: .10,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle,
      false,
      glow,
    );

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(
        alpha: .075,
      );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle,
      false,
      base,
    );

    final progress = (speed / maxSpeed)
        .clamp(0.0, 1.0);

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = RacingHudDashboard._red
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        1.5,
      );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepAngle * progress,
      false,
      active,
    );

    final tickPaint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const tickCount = 25;

    for (var i = 0; i <= tickCount; i++) {
      final t = i / tickCount;
      final angle = startAngle + sweepAngle * t;
      final outer = radius + 13;
      final inner = radius - (i % 5 == 0 ? 8 : 4);

      final p1 = Offset(center.dx + math.cos(angle) * inner, center.dy + math.sin(angle) * inner);
      final p2 = Offset(center.dx + math.cos(angle) * outer, center.dy + math.sin(angle) * outer);

      tickPaint.color =
          i % 5 == 0
              ? RacingHudDashboard._red.withValues(alpha: .65)
              : Colors.white.withValues(alpha: .18);

      canvas.drawLine(p1, p2, tickPaint);

      if (i % 5 == 0) {
        final value = (maxSpeed * t).round();
        final labelPosition = Offset(center.dx + math.cos(angle) * (radius - 25), center.dy + math.sin(angle) * (radius - 25));
        final painter = TextPainter(
          text: TextSpan(
            text: '$value',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .42),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        painter.layout();
        painter.paint(canvas, labelPosition - Offset(painter.width / 2, painter.height / 2));
      }
    }

    final centerLine = Paint()
      ..color = RacingHudDashboard._red.withValues(alpha: .12)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(center.dx, center.dy - radius * .48), Offset(center.dx, center.dy + radius * .42), centerLine);
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) => oldDelegate.speed != speed || oldDelegate.maxSpeed != maxSpeed;
}

class _VehicleGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: CustomPaint(
        painter: _VehiclePainter(),
      ),
    );
  }
}

class _VehiclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = RacingHudDashboard._red.withValues(alpha: .14);

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: size.width * .86, height: size.height * .68), ringPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: size.width * .66, height: size.height * .52), ringPaint);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [RacingHudDashboard._red.withValues(alpha: .20), RacingHudDashboard._red.withValues(alpha: .04), Colors.transparent],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy + size.height * .23), width: size.width * .72, height: size.height * .35));

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .23), width: size.width * .72, height: size.height * .35), glow);

    final body = Path();
    body.moveTo(size.width * .27, size.height * .70);
    body.lineTo(size.width * .33, size.height * .39);
    body.quadraticBezierTo(size.width * .38, size.height * .22, size.width * .50, size.height * .20);
    body.quadraticBezierTo(size.width * .62, size.height * .22, size.width * .67, size.height * .39);
    body.lineTo(size.width * .73, size.height * .70);
    body.quadraticBezierTo(size.width * .76, size.height * .79, size.width * .68, size.height * .84);
    body.lineTo(size.width * .32, size.height * .84);
    body.quadraticBezierTo(size.width * .24, size.height * .79, size.width * .27, size.height * .70);

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE5E8E9), Color(0xFF9DA3A6), Color(0xFF464B4E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(body, bodyPaint);

    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white.withValues(alpha: .30);
    canvas.drawPath(body, outline);

    final window = Path();
    window.moveTo(size.width * .36, size.height * .40);
    window.quadraticBezierTo(size.width * .40, size.height * .28, size.width * .50, size.height * .27);
    window.quadraticBezierTo(size.width * .60, size.height * .28, size.width * .64, size.height * .40);
    window.lineTo(size.width * .61, size.height * .47);
    window.lineTo(size.width * .39, size.height * .47);
    window.close();

    final windowPaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF1B2022), Color(0xFF050708)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(window, windowPaint);

    final divider = Paint()..color = Colors.white.withValues(alpha: .12)..strokeWidth = 1;
    canvas.drawLine(Offset(cx, size.height * .29), Offset(cx, size.height * .47), divider);

    final lightPaint = Paint()..color = RacingHudDashboard._red..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .30, size.height * .58, size.width * .13, size.height * .055), const Radius.circular(3)), lightPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .57, size.height * .58, size.width * .13, size.height * .055), const Radius.circular(3)), lightPaint);

    final centerLight = Paint()..color = RacingHudDashboard._red..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width * .46, size.height * .73), Offset(size.width * .54, size.height * .73), centerLight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FuelIndicator extends StatelessWidget {
  const _FuelIndicator({
    required this.percent,
  });

  final int percent;

  @override
  Widget build(BuildContext context) {
    final active =
        (percent / 100 * 8).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.local_gas_station_outlined,
          color: RacingHudDashboard._muted,
          size: 13,
        ),
        const SizedBox(width: 8),
        ...List.generate(
          8,
          (index) {
            final isActive =
                index < active;

            return Container(
              width: 12,
              height: 5,
              margin:
                  const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? RacingHudDashboard._red
                    : Colors.white.withValues(
                        alpha: .08,
                      ),
                borderRadius:
                    BorderRadius.circular(1),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color:
                              RacingHudDashboard._red,
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
        const SizedBox(width: 5),
        Text(
          '$percent%',
          style: const TextStyle(
            color: RacingHudDashboard._white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.coolant,
    required this.voltage,
    required this.rpm,
    required this.connected,
  });

  final double coolant;
  final double voltage;
  final double rpm;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RacingHudDashboard._surface2
            .withValues(alpha: .78),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              RacingHudDashboard._red
                  .withValues(alpha: .28),
        ),
        boxShadow: [
          BoxShadow(
            color:
                RacingHudDashboard._red
                    .withValues(alpha: .035),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoHeader(
            connected: connected,
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PrimaryStats(
                    coolant: coolant,
                    voltage: voltage,
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: _SecondaryStats(
                      rpm: rpm,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const _DriveFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({
    required this.connected,
  });

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Colors.white.withValues(
              alpha: .055,
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: connected
                      ? RacingHudDashboard._red
                      : Colors.white24,
                  shape: BoxShape.circle,
                  boxShadow: connected
                      ? const [
                          BoxShadow(
                            color:
                                RacingHudDashboard
                                    ._red,
                            blurRadius: 7,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                connected
                    ? 'LIVE DATA'
                    : 'WAITING',
                style: const TextStyle(
                  color:
                      RacingHudDashboard._muted,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Text(
            'DASHCORE',
            style: TextStyle(
              color:
                  RacingHudDashboard._white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStats extends StatelessWidget {
  const _PrimaryStats({
    required this.coolant,
    required this.voltage,
  });

  final double coolant;
  final double voltage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LargeStat(
            label: 'COOLANT',
            value: coolant.toStringAsFixed(0),
            unit: '°C',
            danger: coolant >= 105,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LargeStat(
            label: 'BATTERY',
            value: voltage > 0
                ? voltage.toStringAsFixed(1)
                : '--',
            unit: 'V',
            danger:
                voltage > 0 && voltage < 12.0,
          ),
        ),
      ],
    );
  }
}

class _LargeStat extends StatelessWidget {
  const _LargeStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.danger,
  });

  final String label;
  final String value;
  final String unit;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Colors.orange
        : RacingHudDashboard._white;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: .018,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: .055,
          ),
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color:
                  RacingHudDashboard._muted,
              fontSize: 7,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 25,
                  height: .9,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [
                    FontFeature
                        .tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 2,
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    color:
                        RacingHudDashboard
                            ._red,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryStats extends StatelessWidget {
  const _SecondaryStats({
    required this.rpm,
  });

  final double rpm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricCard(
          label: 'ENGINE RPM',
          value: rpm.toStringAsFixed(0),
          unit: 'RPM',
          progress:
              (rpm / 8000).clamp(0.0, 1.0),
        ),
        const SizedBox(height: 10),
        _SystemStatus(),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    this.danger = false,
  });

  final String label;
  final String value;
  final String unit;
  final double progress;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger
        ? Colors.orange
        : RacingHudDashboard._red;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: .014,
        ),
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: .05,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color:
                      RacingHudDashboard._muted,
                  fontSize: 7,
                  letterSpacing: 1.8,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        color:
                            RacingHudDashboard
                                ._white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        color: accent,
                        fontSize: 7,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    Colors.white.withValues(
                  alpha: .055,
                ),
                valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                  accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: RacingHudDashboard._red
              .withValues(alpha: .035),
          borderRadius:
              BorderRadius.circular(11),
          border: Border.all(
            color: RacingHudDashboard._red
                .withValues(alpha: .10),
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              'SYSTEM STATUS',
              style: TextStyle(
                color:
                    RacingHudDashboard._muted,
                fontSize: 7,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: const [
                _StatusDot(
                  label: 'ENGINE',
                ),
                _StatusDot(
                  label: 'OBD',
                ),
                _StatusDot(
                  label: 'SENSORS',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color:
                RacingHudDashboard._red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    RacingHudDashboard._red,
                blurRadius: 7,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color:
                RacingHudDashboard._muted,
            fontSize: 6,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _DriveFooter extends StatelessWidget {
  const _DriveFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(
              alpha: .05,
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car_outlined,
                size: 12,
                color:
                    RacingHudDashboard._red,
              ),
              const SizedBox(width: 6),
              const Text(
                'DRIVE MODE',
                style: TextStyle(
                  color:
                      RacingHudDashboard._muted,
                  fontSize: 6,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Text(
            'SPORT',
            style: TextStyle(
              color:
                  RacingHudDashboard._red,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              shadows: const [
                Shadow(
                  color:
                      RacingHudDashboard._red,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.05,
            colors: [
              Colors.transparent,
              Colors.black.withValues(
                alpha: .18,
              ),
              Colors.black.withValues(
                alpha: .72,
              ),
            ],
            stops: const [
              0,
              .70,
              1,
            ],
          ),
        ),
      ),
    );
  }
}

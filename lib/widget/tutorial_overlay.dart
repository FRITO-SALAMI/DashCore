import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';
import 'tutorial/tutorial_keys.dart';

/// Guía cinematográfica que se superpone a la UI REAL de DashCore.
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  const TutorialOverlay({super.key, required this.onFinish});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _positionTimer;
  Rect _targetRect = Rect.zero;
  int _metricIndex = 0;
  int _missingTargetTicks = 0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) _updateTargetRect();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateTargetRect() {
    if (!mounted) return;
    final settings = context.read<DashSettingsProvider>();
    final key = _targetFor(settings.tutorialStep);
    if (key == null) {
      _missingTargetTicks = 0;
      if (_targetRect != Rect.zero) setState(() => _targetRect = Rect.zero);
      return;
    }

    final render = key.currentContext?.findRenderObject();
    if (render is! RenderBox || !render.attached) {
      _missingTargetTicks++;
      if (_missingTargetTicks == 20) setState(() {});
      return;
    }

    _missingTargetTicks = 0;

    final offset = render.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(
      offset.dx - 10,
      offset.dy - 10,
      render.size.width + 20,
      render.size.height + 20,
    );
    if (_targetRect != rect) setState(() => _targetRect = rect);
  }

  GlobalKey? _targetFor(int step) {
    switch (step) {
      case 0:
      case 1:
        return TutorialKeys.dashboardKey;
      case 2:
        return TutorialKeys.storeMenuEntryKey;
      case 3:
        return TutorialKeys.freeCategoryKey;
      case 4:
        return TutorialKeys.freeStyleDownloadKey;
      case 5:
        return TutorialKeys.stylesMenuEntryKey;
      case 6:
        return TutorialKeys.applyStyleButtonKey;
      case 7:
        if (_metricIndex == 0) return TutorialKeys.speedGaugeKey;
        if (_metricIndex == 1) return TutorialKeys.temperatureGaugeKey;
        return TutorialKeys.voltageGaugeKey;
      case 8:
        return TutorialKeys.editorMenuEntryKey;
      case 9:
        return TutorialKeys.workshopMenuEntryKey;
      case 10:
        return TutorialKeys.workshopColorKey;
      case 11:
        return TutorialKeys.settingsMenuEntryKey;
      case 12:
        return TutorialKeys.loginButtonKey;
      default:
        return null;
    }
  }

  void _next() {
    final settings = context.read<DashSettingsProvider>();
    final step = settings.tutorialStep;

    if (step == 7) {
      if (_metricIndex < 2) {
        setState(() => _metricIndex++);
      } else {
        setState(() => _metricIndex = 0);
        settings.setTutorialStep(8);
      }
      return;
    }

    if (step == 13) {
      _completeTutorial();
      return;
    }

    settings.nextTutorialStep();
  }

  Future<void> _completeTutorial() async {
    final settings = context.read<DashSettingsProvider>();
    settings.setTutorialActive(false);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final loc = AppLocalizations.of(context);
    final isSpanish = loc.language == Language.spanish;
    final step = settings.tutorialStep;

    String title = "";
    String description = "";
    bool showNext = false;
    String nextLabel = isSpanish ? 'SIGUIENTE' : 'NEXT';

    switch (step) {
      case 0:
        title = isSpanish ? 'BIENVENIDO A DASHCORE' : 'WELCOME TO DASHCORE';
        description = isSpanish
            ? 'Personaliza tu experiencia y descubre todo lo que puedes hacer.'
            : 'Customize your experience and discover everything you can do.';
        showNext = true;
        break;
      case 1:
        title = isSpanish ? 'ACCESO RÁPIDO' : 'QUICK ACCESS';
        description = isSpanish
            ? 'Toca dos veces cualquier parte de la pantalla para abrir el menú lateral.'
            : 'Double-tap anywhere on the screen to open the side menu.';
        break;
      case 2:
        title = isSpanish ? 'NUEVOS DISEÑOS' : 'NEW DESIGNS';
        description = isSpanish
            ? 'Descubre nuevos dashboards y personaliza completamente tu experiencia.'
            : 'Discover new dashboards and fully customize your experience.';
        break;
      case 3:
        title = isSpanish ? 'DISEÑOS GRATUITOS' : 'FREE DESIGNS';
        description = isSpanish
            ? 'Explora los estilos disponibles gratuitamente.'
            : 'Explore the styles available for free.';
        break;
      case 4:
        title = isSpanish ? 'DESCARGAR UN DISEÑO' : 'DOWNLOAD A DESIGN';
        description = isSpanish
            ? 'Toca aquí para añadir RACING PRO a tu colección.'
            : 'Tap here to add RACING PRO to your collection.';
        break;
      case 5:
        title = isSpanish ? 'TU COLECCIÓN' : 'YOUR COLLECTION';
        description = isSpanish
            ? 'Todos los diseños descargados estarán disponibles aquí.'
            : 'All downloaded designs will be available here.';
        break;
      case 6:
        title = isSpanish ? 'APLICA TU NUEVO ESTILO' : 'APPLY YOUR NEW STYLE';
        description = isSpanish
            ? 'Selecciona el diseño para utilizarlo en tu dashboard.'
            : 'Select the design to use it on your dashboard.';
        break;
      case 7:
        final labels = isSpanish
            ? [
                ['VELOCIDAD', 'Visualiza tu velocidad en tiempo real.'],
                [
                  'TEMPERATURA',
                  'Mantén controlados los datos importantes de tu vehículo.',
                ],
                ['VOLTAJE', 'Consulta el estado eléctrico de tu vehículo.'],
              ]
            : [
                ['SPEED', 'See your speed in real time.'],
                ['TEMPERATURE', 'Keep your vehicle data under control.'],
                ['VOLTAGE', 'Check the electrical state of your vehicle.'],
              ];
        title = labels[_metricIndex][0];
        description = labels[_metricIndex][1];
        showNext = true;
        nextLabel = _metricIndex == 2
            ? (isSpanish ? 'CONTINUAR' : 'CONTINUE')
            : (isSpanish ? 'SIGUIENTE' : 'NEXT');
        break;
      case 8:
        title = isSpanish ? 'HAZLO TUYO' : 'MAKE IT YOURS';
        description = isSpanish
            ? 'Entra en EDITAR y cambia los colores de tu dashboard.'
            : 'Enter EDIT and change your dashboard colors.';
        break;
      case 9:
        title = isSpanish
            ? 'PERSONALIZA TU VEHÍCULO'
            : 'CUSTOMIZE YOUR VEHICLE';
        description = isSpanish
            ? 'DashCore también te permite modificar la apariencia de tu vehículo.'
            : 'DashCore also lets you customize your vehicle appearance.';
        break;
      case 10:
        title = isSpanish
            ? 'TU VEHÍCULO, TU ESTILO'
            : 'YOUR VEHICLE, YOUR STYLE';
        description = isSpanish
            ? 'Cambia el color de tu vehículo y haz que combine con tu dashboard.'
            : 'Change your vehicle color and match it to your dashboard.';
        break;
      case 11:
        title = isSpanish
            ? 'SINCRONIZA TU EXPERIENCIA'
            : 'SYNC YOUR EXPERIENCE';
        description = isSpanish
            ? 'Guarda y sincroniza tus preferencias iniciando sesión.'
            : 'Save and sync your preferences by signing in.';
        break;
      case 12:
        title = isSpanish ? 'GUARDA TU EXPERIENCIA' : 'SAVE YOUR EXPERIENCE';
        description = isSpanish
            ? 'Inicia sesión para sincronizar y proteger tus preferencias.'
            : 'Sign in to sync and protect your preferences.';
        break;
      case 13:
      default:
        title = isSpanish ? '✓ TODO LISTO' : '✓ ALL SET';
        description = isSpanish
            ? 'Disfruta DashCore. Tu experiencia ya está configurada.'
            : 'Enjoy DashCore. Your experience is ready.';
        showNext = true;
        nextLabel = isSpanish ? 'COMENZAR A CONDUCIR' : 'START DRIVING';
        break;
    }

    // The "Next" button is now always available as a safety measure to avoid getting stuck
    final targetVisible = step >= 0 && step <= 12 && _targetRect != Rect.zero;
    final canRecoverFromMissingTarget = step >= 0 && step < 13;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Invisible tap area for double-tap logic (only active in step 1)
          if (step == 1)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  settings.setTutorialStep(2);
                },
              ),
            ),

          if (targetVisible) ...[
            _OutsideTouchBlockers(hole: _targetRect),
            _SpotlightMask(hole: _targetRect, pulse: _pulseController),
            _HandGuide(rect: _targetRect),
          ] else ...[
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(0.72)),
              ),
            ),
          ],

          // Next button always available to ensure the user never gets stuck
          if (canRecoverFromMissingTarget)
            Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: step == 13 ? _completeTutorial : _next,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        nextLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        elevation: 10,
                        shadowColor: const Color(0xFF00E5FF).withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    if (step == 1)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, right: 10),
                        child: Text(
                          "O usa el botón si el gesto falla",
                          style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 46),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11151C).withOpacity(0.97),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.35),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 30),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: step == 12
                            ? () => settings.setTutorialStep(13)
                            : _completeTutorial,
                        child: Text(
                          step == 12
                              ? (isSpanish
                                    ? 'OMITIR POR AHORA'
                                    : 'SKIP FOR NOW')
                              : (isSpanish ? 'OMITIR' : 'SKIP'),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (showNext || canRecoverFromMissingTarget) ...[
                        const SizedBox(width: 22),
                        ElevatedButton(
                          onPressed: step == 13 ? _completeTutorial : _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 13,
                            ),
                          ),
                          child: Text(
                            nextLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightMask extends StatelessWidget {
  final Rect hole;
  final Animation<double> pulse;

  const _SpotlightMask({required this.hole, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          return IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: hole,
                glow: 0.35 + (pulse.value * 0.3),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OutsideTouchBlockers extends StatelessWidget {
  final Rect hole;
  const _OutsideTouchBlockers({required this.hole});

  Widget _block() => const ColoredBox(color: Colors.transparent);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final left = hole.left.clamp(0.0, size.width).toDouble();
    final top = hole.top.clamp(0.0, size.height).toDouble();
    final right = hole.right.clamp(0.0, size.width).toDouble();
    final bottom = hole.bottom.clamp(0.0, size.height).toDouble();

    return Stack(
      children: [
        if (top > 0)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: _block(),
            ),
          ),
        if (bottom < size.height)
          Positioned(
            left: 0,
            right: 0,
            top: bottom,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: _block(),
            ),
          ),
        if (left > 0)
          Positioned(
            left: 0,
            top: top,
            width: left,
            height: (bottom - top).clamp(0.0, size.height).toDouble(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: _block(),
            ),
          ),
        if (right < size.width)
          Positioned(
            left: right,
            top: top,
            right: 0,
            height: (bottom - top).clamp(0.0, size.height).toDouble(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: _block(),
            ),
          ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect hole;
  final double glow;

  const _SpotlightPainter({required this.hole, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withOpacity(0.84);
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(16)));
    final screenPath = Path()..addRect(Offset.zero & size);

    canvas.drawPath(
      Path.combine(PathOperation.difference, screenPath, holePath),
      overlay,
    );

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF00E5FF).withOpacity(glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole, const Radius.circular(16)),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.glow != glow;
}

class _HandGuide extends StatefulWidget {
  final Rect rect;
  const _HandGuide({required this.rect});

  @override
  State<_HandGuide> createState() => _HandGuideState();
}

class _HandGuideState extends State<_HandGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _movement;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _movement = Tween<double>(
      begin: 0,
      end: 12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _targetCenter();
    final size = MediaQuery.of(context).size;
    final safeLeft = center.dx.clamp(30.0, size.width - 30.0);
    final safeTop = (center.dy + 34).clamp(40.0, size.height - 130.0);

    return Positioned(
      left: safeLeft - 30,
      top: safeTop - 30,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _movement,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _movement.value),
            child: child,
          ),
          child: Image.asset(
            'assets/tutorial/hand_pointer.png',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }

  Offset _targetCenter() {
    if (widget.rect == Rect.zero) return Offset.zero;
    return widget.rect.center;
  }
}

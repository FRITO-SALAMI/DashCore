import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';

/// Pantalla ficticia e interactiva exclusiva para el tutorial.
/// Simula el dashboard en tiempo real y guía al usuario paso a paso
/// respondiendo a sus toques sin depender del hardware ni del estado de la app.
class InteractiveTutorialScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const InteractiveTutorialScreen({super.key, required this.onFinish});

  @override
  State<InteractiveTutorialScreen> createState() => _InteractiveTutorialScreenState();
}

class _InteractiveTutorialScreenState extends State<InteractiveTutorialScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  bool _isMenuOpen = false;
  Color _accentColor = const Color(0xFF00E5FF); // Cian eléctrico inicial
  String _selectedThemeName = 'Sporty Cyan';
  int _selectedConnectionMode = 0; // 0: OBD2, 1: GPS, 2: Demo
  bool _isPlayingMusic = true;
  String _currentSong = 'Nightcall - Kavinsky';

  // Simulación física de velocímetro y tacómetro
  Timer? _telemetryTimer;
  double _simulatedSpeed = 48.0;
  double _simulatedRpm = 2400.0;
  double _pulsePhase = 0.0;

  late AnimationController _handAnimController;
  late Animation<double> _handBobAnimation;

  @override
  void initState() {
    super.initState();
    _handAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _handBobAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _handAnimController, curve: Curves.easeInOut),
    );

    _startTelemetrySimulation();
  }

  void _startTelemetrySimulation() {
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _pulsePhase += 0.08;
        _simulatedSpeed = 50.0 + (math.sin(_pulsePhase) * 12.0);
        _simulatedRpm = 2300.0 + (math.sin(_pulsePhase * 1.5) * 450.0);
      });
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _handAnimController.dispose();
    super.dispose();
  }

  void _advanceStep(int nextStep) {
    debugPrint('🎓 [TUTORIAL] Advancing to step: $nextStep');
    setState(() {
      _step = nextStep;
    });
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    final settings = context.read<DashSettingsProvider>();
    settings.setTutorialActive(false);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isSpanish = loc.language == Language.spanish;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: Stack(
        children: [
          // 1. Dashboard Ficticio en tiempo real
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () {
                debugPrint('🎓 [TUTORIAL] Screen double tapped in step: $_step');
                if (_step == 0) {
                  setState(() {
                    _isMenuOpen = true;
                  });
                  _advanceStep(1);
                }
              },
              child: _buildMockDashboard(isSpanish),
            ),
          ),

          // 2. Menú lateral interactivo simulado
          if (_isMenuOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 320,
              child: _buildMockSidebar(isSpanish),
            ),

          // 3. Modal interactivo de Tienda de Estilos (Paso 2)
          if (_step == 2)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: _buildThemePickerModal(isSpanish),
                ),
              ),
            ),

          // 4. Spotlight y Guía interactiva paso a paso
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _step == 0 || _step == 1 || _step == 2 || _step == 5,
              child: _buildStepGuidance(isSpanish),
            ),
          ),

          // 5. Botón Omitir (Siempre visible para respetar al usuario)
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(
              child: TextButton.icon(
                onPressed: _completeTutorial,
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                label: Text(
                  isSpanish ? 'OMITIR TUTORIAL' : 'SKIP TUTORIAL',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MOCK DASHBOARD ---
  Widget _buildMockDashboard(bool isSpanish) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            _accentColor.withOpacity(0.08),
            const Color(0xFF07090D),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Barra de estado superior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedConnectionMode == 0
                            ? Icons.bluetooth_connected_rounded
                            : (_selectedConnectionMode == 1
                                ? Icons.gps_fixed_rounded
                                : Icons.play_circle_fill_rounded),
                        color: _accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedConnectionMode == 0
                            ? 'OBD2 CONECTADO (SIM)'
                            : (_selectedConnectionMode == 1 ? 'MODO GPS' : 'MODO DEMO'),
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      const Text('24°C', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text(
                        '12:45',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Clúster Central: Velocímetro + Tacómetro
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Tacómetro (RPM)
                  _buildGauge(
                    title: 'RPM',
                    value: (_simulatedRpm / 1000).toStringAsFixed(1),
                    unit: 'x1000',
                    progress: (_simulatedRpm / 8000).clamp(0.0, 1.0),
                    color: _accentColor,
                  ),

                  // Centro: Velocidad Digital y Marcha
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GEAR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accentColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          'D4',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _simulatedSpeed.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: -2,
                        ),
                      ),
                      const Text(
                        'KM / H',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),

                  // Medidor de Batería / Temp
                  _buildGauge(
                    title: 'VOLTS',
                    value: '14.2',
                    unit: 'V',
                    progress: 0.72,
                    color: Colors.amberAccent,
                  ),
                ],
              ),
            ),

            // Barra inferior de música interactiva (Paso 5)
            _buildMockMusicBar(isSpanish),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge({
    required String title,
    required String value,
    required String unit,
    required double progress,
    required Color color,
  }) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(170, 170),
            painter: _MockGaugePainter(progress: progress, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockMusicBar(bool isSpanish) {
    final bool isHighlighted = _step == 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? _accentColor.withOpacity(0.18) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? _accentColor : Colors.white10,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, color: _accentColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentSong,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isPlayingMusic
                      ? (isSpanish ? 'Reproduciendo en Spotify' : 'Playing on Spotify')
                      : (isSpanish ? 'En pausa' : 'Paused'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isPlayingMusic ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: _accentColor,
              size: 34,
            ),
            onPressed: () {
              setState(() {
                _isPlayingMusic = !_isPlayingMusic;
              });
              if (_step == 5) {
                _advanceStep(6);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 26),
            onPressed: () {
              setState(() {
                _currentSong = _currentSong.contains('Kavinsky')
                    ? 'Blinding Lights - The Weeknd'
                    : 'Nightcall - Kavinsky';
              });
              if (_step == 5) {
                _advanceStep(6);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- MOCK SIDEBAR ---
  Widget _buildMockSidebar(bool isSpanish) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10131A).withOpacity(0.97),
        border: const Border(right: BorderSide(color: Colors.white12)),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 40)],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_accentColor, _accentColor.withOpacity(0.4)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.speed_rounded, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'DASHCORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildMenuItem(
                    icon: Icons.storefront_rounded,
                    title: isSpanish ? 'Tienda de Estilos' : 'Styles Store',
                    isHighlighted: _step == 1,
                    onTap: () {
                      if (_step == 1) {
                        _advanceStep(2);
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.palette_rounded,
                    title: isSpanish ? 'Iluminación & Color' : 'Lighting & Color',
                    isHighlighted: _step == 3,
                    onTap: () {
                      if (_step == 3) {
                        _advanceStep(4);
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_input_component_rounded,
                    title: isSpanish ? 'Conexión OBD2 / GPS' : 'OBD2 / GPS Connection',
                    isHighlighted: _step == 4,
                    onTap: () {
                      if (_step == 4) {
                        _advanceStep(5);
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.tune_rounded,
                    title: isSpanish ? 'Editor de Medidores' : 'Gauge Editor',
                    isHighlighted: false,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    title: isSpanish ? 'Ajustes del Sistema' : 'System Settings',
                    isHighlighted: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            // Cierre de menú
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: () => setState(() => _isMenuOpen = false),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 16),
                label: Text(
                  isSpanish ? 'Cerrar Menú' : 'Close Menu',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? _accentColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? _accentColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isHighlighted ? _accentColor : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isHighlighted ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isHighlighted
            ? Icon(Icons.touch_app_rounded, color: _accentColor, size: 20)
            : const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
        onTap: onTap,
      ),
    );
  }

  // --- THEME PICKER MODAL (PASO 2) ---
  Widget _buildThemePickerModal(bool isSpanish) {
    final themes = [
      {'name': 'Sporty Cyan', 'color': const Color(0xFF00E5FF), 'desc': 'Digital Sport Cluster'},
      {'name': 'Redline Race', 'color': const Color(0xFFFF2A4B), 'desc': 'Track Performance'},
      {'name': 'Cyber Neon', 'color': const Color(0xFF9D00FF), 'desc': 'Futuristic Night'},
      {'name': 'Tesla Minimal', 'color': const Color(0xFF00FF88), 'desc': 'EV Clean Layout'},
    ];

    return Container(
      width: 520,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accentColor.withOpacity(0.4)),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSpanish ? 'TIENDA DE ESTILOS' : 'THEMES STORE',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSpanish ? 'GRATIS EN TUTORIAL' : 'FREE IN TUTORIAL',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: themes.map((theme) {
              final isSelected = _selectedThemeName == theme['name'];
              final themeColor = theme['color'] as Color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedThemeName = theme['name'] as String;
                    _accentColor = themeColor;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? themeColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? themeColor : Colors.white10,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme['name'] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              theme['desc'] as String,
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                _advanceStep(3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isSpanish ? 'APLICAR ESTILO Y CONTINUAR' : 'APPLY STYLE & CONTINUE',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GUÍA Y TOOLTIPS INTERACTIVOS ---
  Widget _buildStepGuidance(bool isSpanish) {
    String title = '';
    String desc = '';
    Widget? interactiveControl;

    switch (_step) {
      case 0:
        title = isSpanish ? '¡BIENVENIDO A DASHCORE!' : 'WELCOME TO DASHCORE!';
        desc = isSpanish
            ? 'TOCA DOS VECES RÁPIDO LA PANTALLA para desplegar el menú lateral de controles.'
            : 'DOUBLE TAP FAST ON THE SCREEN to reveal the quick controls menu.';
        break;

      case 1:
        title = isSpanish ? 'MENÚ PRINCIPAL' : 'MAIN MENU';
        desc = isSpanish
            ? '¡Excelente! Toca "Tienda de Estilos" en el menú para personalizar el diseño del tacómetro.'
            : 'Great! Tap "Styles Store" in the menu to customize the speedometer design.';
        break;

      case 2:
        title = isSpanish ? 'ELIGE TU ESTILO' : 'CHOOSE YOUR STYLE';
        desc = isSpanish
            ? 'Toca un diseño para previsualizar el cambio y pulsa "Aplicar Estilo".'
            : 'Tap any design to preview it and press "Apply Style".';
        break;

      case 3:
        title = isSpanish ? 'ILUMINACIÓN AMBIENTAL' : 'AMBIENT LIGHTING';
        desc = isSpanish
            ? 'Toca cualquier color abajo para sincronizar la iluminación con tu automóvil:'
            : 'Tap any color below to match the ambient lights of your car:';
        interactiveControl = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildColorDot(const Color(0xFF00E5FF)),
            _buildColorDot(const Color(0xFFFF2A4B)),
            _buildColorDot(const Color(0xFF00FF88)),
            _buildColorDot(const Color(0xFFFF9100)),
            _buildColorDot(const Color(0xFF9D00FF)),
          ],
        );
        break;

      case 4:
        title = isSpanish ? 'TELEMETRÍA Y CONECTIVIDAD' : 'TELEMETRY & MODES';
        desc = isSpanish
            ? 'Selecciona cómo leerá DashCore los datos de tu coche:'
            : 'Select how DashCore will read your vehicle telemetry:';
        interactiveControl = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeButton(0, 'OBD2 BLUETOOTH', Icons.bluetooth_rounded),
            const SizedBox(width: 10),
            _buildModeButton(1, 'MODO GPS', Icons.gps_fixed_rounded),
            const SizedBox(width: 10),
            _buildModeButton(2, 'MODO DEMO', Icons.play_arrow_rounded),
          ],
        );
        break;

      case 5:
        title = isSpanish ? 'CONTROL MULTIMEDIA' : 'MEDIA CONTROLS';
        desc = isSpanish
            ? 'Usa los controles de la barra inferior para reproducir, pausar o pasar de canción.'
            : 'Use the bottom bar controls to play, pause, or skip tracks on the go.';
        break;

      case 6:
        title = isSpanish ? '¡TODO LISTO PARA CONDUCIR!' : 'READY TO DRIVE!';
        desc = isSpanish
            ? 'Has completado la guía inicial. ¡Disfruta de la mejor experiencia en cabina con DashCore!'
            : 'You have completed the guide. Enjoy the ultimate dashboard experience with DashCore!';
        interactiveControl = Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    url_launcher.launchUrl(
                      Uri.parse('https://play.google.com/store/apps/details?id=io.dashcore.app'),
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 20),
                  label: Text(
                    isSpanish ? 'VALORAR EN PLAY STORE' : 'RATE ON PLAY STORE',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _completeTutorial,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                  label: Text(
                    isSpanish ? 'COMENZAR A RODAR' : 'START DRIVING',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        );
        break;
    }

    return Stack(
      children: [
        // Indicador de mano animada para guiar el toque
        if (_step == 0)
          Center(
            child: AnimatedBuilder(
              animation: _handBobAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _handBobAnimation.value),
                child: Image.asset('assets/tutorial/hand_pointer.png', width: 64, height: 64),
              ),
            ),
          ),

        // Caja de información inferior
        Positioned(
          bottom: 24,
          left: _isMenuOpen ? 340 : 60,
          right: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF10141D).withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (interactiveControl != null) ...[
                  const SizedBox(height: 12),
                  interactiveControl,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = _accentColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _accentColor = color;
        });
        if (_step == 3) {
          _advanceStep(4);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 10),
          ],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 18) : null,
      ),
    );
  }

  Widget _buildModeButton(int mode, String label, IconData icon) {
    final isSelected = _selectedConnectionMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedConnectionMode = mode;
        });
        if (_step == 4) {
          _advanceStep(5);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? _accentColor : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter para diales del dashboard simulado
class _MockGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _MockGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    // Fondo del arco
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Arco activo con color ambiental
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress.clamp(0.0, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MockGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

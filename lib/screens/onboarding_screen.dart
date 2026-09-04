import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/dash_settings_provider.dart';
import '../providers/obd_provider.dart';
import '../utils/app_localizations.dart';
import 'vehicle_resource_download_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingPermissions = false;
  bool _showCinematic = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _showCinematic = false);
      _checkInitialPermissions();
    });
  }

  Future<void> _checkInitialPermissions() async {
    final status = await Permission.location.status;
    if (status.isGranted && _currentPage == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(1);
        }
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (_isRequestingPermissions) return;
    setState(() => _isRequestingPermissions = true);

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdk = androidInfo.version.sdkInt;

    final List<Permission> permissionsToRequest = [
      Permission.notification,
      Permission.location,
      Permission.bluetooth,
      Permission.camera, // For potential future use or AR
    ];

    if (sdk >= 31) {
      permissionsToRequest.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ]);
      permissionsToRequest.add(Permission.locationWhenInUse);
    }

    final Map<Permission, PermissionStatus> statuses =
        await permissionsToRequest.request();

    setState(() => _isRequestingPermissions = false);

    final bool locationGranted =
        statuses[Permission.location]?.isGranted == true ||
        statuses[Permission.locationWhenInUse]?.isGranted == true;
    final bool bluetoothGranted = sdk >= 31
        ? (statuses[Permission.bluetoothScan]?.isGranted == true &&
              statuses[Permission.bluetoothConnect]?.isGranted == true)
        : (statuses[Permission.bluetooth]?.isGranted == true ||
              statuses[Permission.location]?.isGranted == true);

    if (locationGranted || bluetoothGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _skipTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    final settings = context.read<DashSettingsProvider>();
    settings.setTutorialActive(false);
    widget.onFinish();
  }

  void _nextPage() {
    if (_currentPage == 4) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    final settings = context.read<DashSettingsProvider>();
    settings.setTutorialActive(
      true,
    ); // Start the dashboard part of the tutorial
    settings.setTutorialStep(0);
    widget.onFinish();
  }

  Future<void> _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CACHE LIMPIADA - REINICIANDO...')),
      );
      Future.delayed(const Duration(seconds: 1), () {
        SystemNavigator.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCinematic) {
      return const _BootCinematic();
    }

    final loc = AppLocalizations.of(context);
    final themeColor = const Color(0xFF00E5FF);
    final settings = context.watch<DashSettingsProvider>();
    final obdProvider = context.read<ObdProvider>();
    final isSpanish = loc.language == Language.spanish;

    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          Positioned.fill(child: _PremiumBackground(color: themeColor)),

          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: [
              _buildPermissionsPage(isSpanish, themeColor),
              _buildWelcomePage(isSpanish, themeColor),
              _buildModeSelectionPage(loc, themeColor, settings, obdProvider),
              _buildVehicleSelectionPage(loc, themeColor, settings),
              _buildLanguagePage(loc, themeColor, settings),
            ],
          ),

          // Top Navigation (Skip/Next) - Visible from Step 2 (Page 1)
          if (_currentPage >= 1)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skipTutorial,
                    child: Text(
                      isSpanish ? 'OMITIR' : 'SKIP',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _nextPage,
                    child: Text(
                      isSpanish ? 'SIGUIENTE' : 'NEXT',
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => _buildDot(i, themeColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? color : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPermissionsPage(bool isSpanish, Color themeColor) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 40),
              Text(
                isSpanish
                    ? 'ACEPTA LOS PERMISOS NECESARIOS\nPARA CONTINUAR'
                    : 'ACCEPT THE NECESSARY PERMISSIONS\nTO CONTINUE',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 60),
              _PremiumButton(
                label: isSpanish ? 'DAR PERMISOS' : 'GRANT PERMISSIONS',
                onTap: _requestPermissions,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _resetApp,
                child: Text(
                  isSpanish
                      ? 'RESTABLECER APP / BORRAR CACHE'
                      : 'RESET APP / CLEAR CACHE',
                  style: const TextStyle(
                    color: Colors.white12,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Hand guide pointing to system dialog area
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: _AnimatedHandGuide(offset: const Offset(0, 50)),
        ),
      ],
    );
  }

  Widget _buildWelcomePage(bool isSpanish, Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'logo',
            child: Image.asset('assets/icons/dashcore_logo.png', width: 150),
          ),
          const SizedBox(height: 50),
          const Text(
            'DASHCORE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isSpanish ? 'Comienza la experiencia' : 'The experience begins',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 80),
          _PremiumButton(
            label: isSpanish ? 'COMENZAR TUTORIAL' : 'START TUTORIAL',
            onTap: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectionPage(
    AppLocalizations loc,
    Color themeColor,
    DashSettingsProvider settings,
    ObdProvider obdProvider,
  ) {
    final isSpanish = loc.language == Language.spanish;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_input_component_rounded,
            color: themeColor,
            size: 80,
          ),
          const SizedBox(height: 30),
          Text(
            isSpanish ? 'ELIGE TU MODO' : 'CHOOSE YOUR MODE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 40),
          _SelectionCard(
            label: 'OBD2',
            icon: Icons.bluetooth_connected_rounded,
            isSelected: !settings.isNoObdMode,
            onTap: () {
              settings.toggleNoObdMode(false);
              obdProvider.stopGpsMode();
            },
          ),
          const SizedBox(height: 12),
          _SelectionCard(
            label: 'GPS',
            icon: Icons.location_on_rounded,
            isSelected: settings.isNoObdMode,
            onTap: () {
              settings.toggleNoObdMode(true);
              obdProvider.toggleGpsMode();
            },
          ),
          const SizedBox(height: 60),
          _PremiumButton(
            label: isSpanish ? 'CONTINUAR' : 'CONTINUE',
            onTap: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionPage(
    AppLocalizations loc,
    Color themeColor,
    DashSettingsProvider settings,
  ) {
    final isSpanish = loc.language == Language.spanish;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_car_rounded, color: themeColor, size: 60),
        const SizedBox(height: 20),
        Text(
          isSpanish ? 'SELECCIONA TU VEHÍCULO' : 'SELECT YOUR VEHICLE',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 30),
        if (settings.vehiclesLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else if (settings.availableVehicles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 24),
            child: Text(
              'NO SE PUDO CARGAR EL CATÁLOGO. VERIFICA INTERNET Y LA TABLA VEHICLES.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orangeAccent),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              itemCount: settings.availableVehicles.length,
              itemBuilder: (context, index) {
                final v = settings.availableVehicles[index];
                final isSelected = settings.selectedVehicle?.id == v.id;
                return GestureDetector(
                  onTap: () async {
                    if (v.isDownloaded) {
                      settings.selectVehicle(v);
                      return;
                    }
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            VehicleResourceDownloadScreen(vehicle: v),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? themeColor.withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? themeColor : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: isSelected ? themeColor : Colors.white24,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          v.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 40),
        _PremiumButton(
          label: isSpanish ? 'SIGUIENTE' : 'NEXT',
          onTap: () {
            if (settings.selectedVehicle?.isDownloaded == true) {
              _nextPage();
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'SELECCIONA Y DESCARGA UN VEHÍCULO PARA CONTINUAR',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguagePage(
    AppLocalizations loc,
    Color themeColor,
    DashSettingsProvider settings,
  ) {
    final isSpanish = loc.language == Language.spanish;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language_rounded, color: themeColor, size: 80),
          const SizedBox(height: 30),
          Text(
            isSpanish ? 'SELECCIONA TU IDIOMA' : 'SELECT YOUR LANGUAGE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 40),
          _LangOption(
            label: 'ESPAÑOL',
            isSelected: settings.language == Language.spanish,
            onTap: () => settings.setLanguage(Language.spanish),
          ),
          const SizedBox(height: 12),
          _LangOption(
            label: 'ENGLISH',
            isSelected: settings.language == Language.english,
            onTap: () => settings.setLanguage(Language.english),
          ),
          const SizedBox(height: 60),
          _PremiumButton(
            label: isSpanish ? 'FINALIZAR' : 'FINISH',
            onTap: _finishOnboarding,
          ),
        ],
      ),
    );
  }
}

class _BootCinematic extends StatefulWidget {
  const _BootCinematic();

  @override
  State<_BootCinematic> createState() => _BootCinematicState();
}

class _BootCinematicState extends State<_BootCinematic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _needle;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _jitter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _needle = TweenSequence<double>([
      // Aggressive sweep to max
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 30,
      ),
      // Slight bounce at the top
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      // Hold with jitter (handled by _jitter)
      TweenSequenceItem(tween: ConstantTween(0.9), weight: 20),
      // Smooth return to zero
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 0.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40,
      ),
    ]).animate(_controller);

    _jitter = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(
        tween: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.02), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.02, end: -0.02), weight: 1),
        ]),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
    ]).animate(_controller);

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030508),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 350,
                  height: 250,
                  child: CustomPaint(
                    painter: _BootGaugePainter(progress: (_needle.value + _jitter.value).clamp(0.0, 1.0)),
                  ),
                ),
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/dashcore_logo.png',
                          width: 130,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'DASHCORE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BootGaugePainter extends CustomPainter {
  final double progress;
  const _BootGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = size.width * 0.40;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withOpacity(0.08);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00E5FF).withOpacity(0.72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00E5FF);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi * 1.15, math.pi * 0.70, false, base);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        math.pi * 1.15,
        math.pi * 0.70 * progress,
        false,
        glow,
      );
      canvas.drawArc(
        rect,
        math.pi * 1.15,
        math.pi * 0.70 * progress,
        false,
        active,
      );
    }

    final angle = math.pi * 1.15 + (math.pi * 0.70 * progress);
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 10);
    final needle = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, needle);
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant _BootGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AnimatedHandGuide extends StatefulWidget {
  final Offset offset;
  const _AnimatedHandGuide({required this.offset});
  @override
  State<_AnimatedHandGuide> createState() => _AnimatedHandGuideState();
}

class _AnimatedHandGuideState extends State<_AnimatedHandGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: widget.offset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: _animation.value,
        child: Image.asset(
          'assets/tutorial/hand_pointer.png',
          width: 60,
          height: 60,
        ),
      ),
    );
  }
}

class _PremiumBackground extends StatefulWidget {
  final Color color;
  const _PremiumBackground({required this.color});
  @override
  State<_PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<_PremiumBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(_controller.value * 0.5, _controller.value * 0.2),
            radius: 2.0,
            colors: [widget.color.withOpacity(0.08), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PremiumButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? themeColor : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? themeColor : Colors.white24,
              size: 30,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LangOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? activeColor : Colors.white10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

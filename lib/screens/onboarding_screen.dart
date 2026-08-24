import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/dash_settings_provider.dart';
import '../providers/obd_provider.dart';
import '../utils/app_localizations.dart';
import '../models/vehicle_model.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeColor = Color(0xFF00E5FF);
    final settings = context.watch<DashSettingsProvider>();
    final obdProvider = context.read<ObdProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF050608), 
      body: Stack(
        children: [
          Positioned.fill(
            child: _PremiumBackground(color: themeColor),
          ),
          
          PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: [
              _buildWelcomePage(loc, themeColor),
              _buildModeSelectionPage(loc, themeColor, settings, obdProvider),
              _buildVehicleSelectionPage(loc, themeColor, settings),
              _buildLanguagePage(loc, themeColor, settings),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => _buildDot(i, themeColor)),
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

  Widget _buildWelcomePage(AppLocalizations loc, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [accent.withOpacity(0.05), Colors.transparent],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Image.asset('assets/icons/dashcore_logo.png', width: 150),
            ),
            SizedBox(height: 50),
            Text(
              'DASHCORE', 
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 12),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(
                'PREMIUM EXPERIENCE', 
                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3),
              ),
            ),
            SizedBox(height: 80),
            _PremiumButton(
              label: 'COMENZAR EXPERIENCIA', 
              onTap: () => _pageController.nextPage(duration: Duration(milliseconds: 500), curve: Curves.easeInOutCubic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelectionPage(AppLocalizations loc, Color themeColor, DashSettingsProvider settings, ObdProvider obdProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_input_component_rounded, color: themeColor, size: 80),
          const SizedBox(height: 30),
          const Text('ELIGE TU MODO', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          _SelectionCard(
            label: 'CONECTAR OBD2',
            icon: Icons.bluetooth_connected_rounded,
            isSelected: !settings.isNoObdMode,
            onTap: () {
              settings.toggleNoObdMode(false);
              obdProvider.stopGpsMode();
            },
          ),
          const SizedBox(height: 12),
          _SelectionCard(
            label: 'MODO SIN OBD (GPS)',
            icon: Icons.location_on_rounded,
            isSelected: settings.isNoObdMode,
            onTap: () {
              settings.toggleNoObdMode(true);
              obdProvider.toggleGpsMode();
            },
          ),
          const SizedBox(height: 60),
          _PremiumButton(
            label: 'CONTINUAR', 
            onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionPage(AppLocalizations loc, Color themeColor, DashSettingsProvider settings) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_car_rounded, color: themeColor, size: 60),
        const SizedBox(height: 20),
        const Text('SELECCIONA TU VEHÍCULO', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 30),
        SizedBox(
          height: 250,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            itemCount: defaultVehicles.length,
            itemBuilder: (context, index) {
              final v = defaultVehicles[index];
              final isSelected = settings.selectedVehicle?.id == v.id;
              return GestureDetector(
                onTap: () => settings.selectVehicle(v),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? themeColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? themeColor : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car, color: isSelected ? themeColor : Colors.white24),
                      const SizedBox(width: 15),
                      Text(v.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 40),
        _PremiumButton(
          label: 'SIGUIENTE', 
          onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _buildLanguagePage(AppLocalizations loc, Color themeColor, DashSettingsProvider settings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language_rounded, color: themeColor, size: 80),
          const SizedBox(height: 30),
          const Text('SELECCIONA TU IDIOMA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          _LangOption(label: 'ESPAÑOL', isSelected: settings.language == Language.spanish, onTap: () => settings.setLanguage(Language.spanish)),
          const SizedBox(height: 12),
          _LangOption(label: 'ENGLISH', isSelected: settings.language == Language.english, onTap: () => settings.setLanguage(Language.english)),
          const SizedBox(height: 60),
          _PremiumButton(
            label: 'FINALIZAR', 
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_done', true);
              widget.onFinish();
            },
          ),
        ],
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

class _PremiumBackgroundState extends State<_PremiumBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
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
            BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 20, spreadRadius: -5),
          ],
        ),
        child: Text(
          label, 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
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
  const _SelectionCard({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? themeColor : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? themeColor : Colors.white24, size: 30),
            const SizedBox(width: 20),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
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
  const _LangOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00E5FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? activeColor : Colors.white10),
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

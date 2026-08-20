import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/dash_settings_provider.dart';
import '../utils/app_localizations.dart';
import 'connect_screen.dart';

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
    const themeColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: const Color(0xFF090B0F),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: [
              _buildWelcomePage(loc, themeColor),
              _buildLanguagePage(loc, themeColor),
              _buildObdPage(loc, themeColor),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => _buildDot(i, themeColor)),
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

  Widget _buildWelcomePage(AppLocalizations loc, Color themeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icons/dashcore_logo.png', width: 120),
          const SizedBox(height: 40),
          const Text('BIENVENIDOS A DASHCORE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          const Text('Tu tablero inteligente de alto rendimiento', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: const Text('EMPEZAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePage(AppLocalizations loc, Color themeColor) {
    final settings = context.watch<DashSettingsProvider>();
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
          ElevatedButton(
            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: const Text('SIGUIENTE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildObdPage(AppLocalizations loc, Color themeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_connected_rounded, color: themeColor, size: 80),
          const SizedBox(height: 30),
          const Text('CONFIGURAR OBD2', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text('Conecta tu dispositivo OBD2 ahora para empezar a recibir datos en tiempo real.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectionScreen(onBack: () => Navigator.pop(context))));
                },
                style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                child: const Text('CONECTAR AHORA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_done', true);
                  widget.onFinish();
                },
                child: const Text('OMITIR Y FINALIZAR', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ],
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
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? activeColor : Colors.white10),
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

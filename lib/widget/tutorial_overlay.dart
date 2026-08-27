import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  const TutorialOverlay({super.key, required this.onFinish});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);
    final loc = AppLocalizations.of(context);
    final isSpanish = loc.translate('lang') == 'IDIOMA';

    final List<Map<String, String>> steps = [
      {
        'title': isSpanish ? 'BIENVENIDO A DASHCORE' : 'WELCOME TO DASHCORE',
        'desc': isSpanish ? 'Tu central de datos y personalización para el vehículo.' : 'Your data and personalization center for your vehicle.',
      },
      {
        'title': isSpanish ? 'MENÚ LATERAL' : 'SIDE MENU',
        'desc': isSpanish ? 'Haz DOBLE TAP en cualquier parte de la pantalla para abrir el menú.' : 'DOUBLE TAP anywhere on the screen to open the menu.',
      },
      {
        'title': isSpanish ? 'PERSONALIZACIÓN' : 'PERSONALIZATION',
        'desc': isSpanish ? 'Desde el menú puedes entrar a EDITAR para mover y añadir indicadores.' : 'From the menu you can enter EDIT to move and add gauges.',
      },
      {
        'title': isSpanish ? 'INICIA SESIÓN' : 'SIGN IN',
        'desc': isSpanish ? 'Sincroniza tus ajustes y estilos favoritos en la nube.' : 'Sync your favorite settings and styles in the cloud.',
      },
    ];

    final current = steps[_step];

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_step),
                      children: [
                        Text(
                          current['title']!,
                          style: const TextStyle(
                            color: themeColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          current['desc']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: widget.onFinish,
                        child: Text(isSpanish ? 'OMITIR' : 'SKIP', style: const TextStyle(color: Colors.white38)),
                      ),
                      const SizedBox(width: 40),
                      ElevatedButton(
                        onPressed: () {
                          if (_step < steps.length - 1) {
                            setState(() => _step++);
                          } else {
                            widget.onFinish();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _step == steps.length - 1 ? (isSpanish ? 'ENTENDIDO' : 'UNDERSTOOD') : (isSpanish ? 'SIGUIENTE' : 'NEXT'),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
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

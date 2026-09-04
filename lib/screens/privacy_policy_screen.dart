import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static const version = '2.0';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('POLÍTICA DE PRIVACIDAD'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: const [
                  _PolicyIntro(),
                  _PolicySection(
                    '1. Responsable del Tratamiento',
                    'DASHCORE, con domicilio en Santo Domingo, República Dominicana y correo electrónico de contacto Dashcoreteam@gmail.com, es el responsable del tratamiento de tus datos personales.',
                  ),
                  _PolicySection(
                    '2. Datos Recopilados y Consentimiento',
                    'Al aceptar esta política, autorizas la recopilación y procesamiento de: datos de cuenta, perfil, dispositivo, vehículo, telemetría OBD2 y diagnósticos. Además, aceptas la activación automática de analítica de uso, monitoreo de rendimiento y seguimiento GPS.',
                  ),
                  _PolicySection(
                    '3. Seguimiento GPS y Ubicación',
                    'El seguimiento GPS se realizará de forma no intrusiva: los datos de ubicación se enviarán únicamente cuando el dispositivo disponga de conexión a internet y con una frecuencia máxima de una vez cada 12 horas. Esta información se utiliza exclusivamente para fines estadísticos de procedencia (país) de nuestros usuarios.',
                  ),
                  _PolicySection(
                    '4. Finalidad del Tratamiento',
                    'Los datos se utilizan para la prestación del servicio, sincronización en la nube, optimización del rendimiento del panel, detección de fallos técnicos y mejora continua de la experiencia DashCore.',
                  ),
                  _PolicySection(
                    '5. Conservación de Datos',
                    'Tus datos personales y de telemetría se conservarán mientras tu cuenta permanezca activa o durante un plazo máximo de 2 años tras tu última actividad, tras lo cual serán eliminados o anonimizados, salvo que solicites su supresión anticipada.',
                  ),
                  _PolicySection(
                    '6. Seguridad y Terceros',
                    'Utilizamos Supabase para la infraestructura de autenticación y base de datos. Los datos viajan cifrados y se almacenan bajo estrictas medidas de seguridad. No compartimos tu información personal con terceros para fines comerciales.',
                  ),
                  _PolicySection(
                    '7. Derechos y Eliminación de Cuenta',
                    'Puedes ejercer tus derechos de acceso, rectificación y supresión. Para eliminar tu cuenta y todos los datos asociados, dirígete a Ajustes > Avanzado > Eliminar Cuenta. También puedes consultar nuestra política extendida en: https://dashcore-web.vercel.app/#Privacidad',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0A1018),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _confirmed,
                    activeColor: accent,
                    checkColor: Colors.black,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'He leído y acepto la Política de Privacidad v2.0',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onChanged: (value) =>
                        setState(() => _confirmed = value ?? false),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _confirmed
                          ? () => Navigator.pop(context, true)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('ACEPTAR Y CONTINUAR'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyIntro extends StatelessWidget {
  const _PolicyIntro();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 18),
    child: Text(
      'Lee cómo DashCore utiliza y protege tus datos antes de continuar.',
      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 17),
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection(this.title, this.body);
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            height: 1.45,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

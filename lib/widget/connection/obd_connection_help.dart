import 'package:flutter/material.dart';

class ObdConnectionHelpButton extends StatelessWidget {
  const ObdConnectionHelpButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Ayuda para conectar OBD2',
    icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF00D5FF)),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => const ObdConnectionHelpDialog(),
    ),
  );
}

class ObdConnectionHelpDialog extends StatelessWidget {
  const ObdConnectionHelpDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF0C1823),
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    scrollable: true,
    title: const Row(
      children: [
        Icon(Icons.bluetooth_connected_rounded, color: Color(0xFF00D5FF)),
        SizedBox(width: 12),
        Expanded(
          child: Text('Conecta tu OBD2', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF103447),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  'PIN BLUETOOTH HABITUAL',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '1234',
                  style: TextStyle(
                    color: Color(0xFF00D5FF),
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _HelpStep(
            icon: Icons.power_rounded,
            title: '1. Conecta el adaptador',
            text:
                'Enchufa el ELM al puerto OBD2 del vehículo y enciende el contacto.',
          ),
          const _HelpStep(
            icon: Icons.settings_bluetooth_rounded,
            title: '2. Abre los ajustes Bluetooth',
            text:
                'Entra en Ajustes → Bluetooth del radio Android o teléfono y activa Bluetooth.',
          ),
          const _HelpStep(
            icon: Icons.pin_rounded,
            title: '3. Configura el PIN de enlace',
            text:
                'Si tu radio permite cambiar su PIN de enlace Bluetooth, ajústalo a 1234 antes de vincular el ELM. Si aparece una solicitud de PIN al emparejar, introduce 1234.',
          ),
          const _HelpStep(
            icon: Icons.link_rounded,
            title: '4. Vincula el OBD2',
            text:
                'Busca el adaptador —puede llamarse OBDII, OBD2 o ELM327— y confirma el emparejamiento.',
          ),
          const _HelpStep(
            icon: Icons.speed_rounded,
            title: '5. Regresa a DashCore',
            text:
                'Activa Bluetooth en esta pantalla, busca tu adaptador, selecciónalo y pulsa CONECTAR.',
          ),
          const Text(
            'El PIN debe coincidir con el de tu adaptador. Si 1234 no funciona, consulta su manual: algunos usan 0000. DashCore no cambia la contraseña interna del ELM.',
            style: TextStyle(
              color: Color(0xFFB3C4CF),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ENTENDIDO'),
      ),
    ],
  );
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title, text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00D5FF), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFB3C4CF),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

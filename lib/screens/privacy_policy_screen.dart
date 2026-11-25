import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  static const version = '3.0';
  static const summary = '''
UBICACIÓN Y OBD EN EL DISPOSITIVO
La posición GPS, el rumbo y el recorrido temporal se procesan en el equipo. Si activas el mapa de Road Atlas, se solicitan teselas del área visible a OpenStreetMap, que puede inferir el área aproximada y ver tu dirección IP. El recorrido no se envía y se descarta al salir de la vista. Las teselas pueden quedar en la caché temporal del equipo.

CUENTA Y SINCRONIZACIÓN
Supabase gestiona la cuenta, perfil, avatar, preferencias, estilos elegidos, catálogo y estadísticas de DashLeague. DashLeague utiliza distancia acumulada y velocidad máxima; no recibe posiciones GPS ni recorridos. Los recursos grandes se descargan bajo demanda.

FOTOS DE TU VEHÍCULO
Tus fotos y GLB importados se usan localmente. En Android, el recorte con IA del garaje se ejecuta en el equipo y conserva el ángulo de la foto. La aplicación guarda las imágenes del garaje sin metadatos GPS.

DIAGNÓSTICO
La medición de rendimiento es opcional y local. Solo se envía un informe técnico cuando tú lo solicitas desde Ajustes. Puedes revisar el mensaje antes de enviarlo.

PERMISOS
Bluetooth permite conectar el adaptador OBD2. La ubicación se solicita al activar una función GPS. Fotos y archivos permiten seleccionar imágenes y recursos. Mantener app activa es opcional y utiliza un servicio visible durante la sesión OBD.

CONTROL Y ELIMINACIÓN
Puedes revocar permisos desde Android y eliminar tu cuenta desde Ajustes. La eliminación afecta solo a tus datos personales, vehículos propios, fotos y avatar; no borra vehículos, estilos ni recursos compartidos de DashCore.

CONTACTO
Dashcoreteam@gmail.com
''';
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080D15),
    appBar: AppBar(title: const Text('PRIVACIDAD · DASHCORE 2.0')),
    body: SafeArea(
      child: Column(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Text(
                summary,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ACEPTAR Y CONTINUAR'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  static const version = '3.0';
  static const summary = '''
UBICACIÓN Y OBD EN EL DISPOSITIVO
La posición GPS, el rumbo y el recorrido temporal se procesan en el equipo. Road Atlas incluye un mapa de Santo Domingo basado en OpenStreetMap. La búsqueda de direcciones y el cálculo de rutas de esa zona funcionan localmente. El recorrido y las búsquedas no se envían a un servicio de mapas. La cobertura y las direcciones disponibles dependen de los datos de OpenStreetMap incluidos en esta versión.

CUENTA Y SINCRONIZACIÓN
Supabase gestiona la cuenta, perfil, avatar, preferencias, estilos elegidos, catálogo y estadísticas de DashLeague. DashLeague utiliza distancia acumulada y velocidad máxima; no recibe posiciones GPS ni recorridos. Los recursos grandes se descargan bajo demanda.

FOTOS DE TU VEHÍCULO
Tus fotos y GLB importados se usan localmente. En Android, el recorte con IA del garaje se ejecuta en el equipo y conserva el ángulo de la foto. La aplicación guarda las imágenes del garaje sin metadatos GPS.

DIAGNÓSTICO
La medición de rendimiento es opcional y local. Solo se envía un informe técnico cuando tú lo solicitas desde Ajustes. Puedes revisar el mensaje antes de enviarlo.

PERMISOS
Android solicita ubicación al activar una función GPS, como velocidad, rumbo o mapa. Bluetooth se solicita al buscar o conectar un adaptador OBD2. En radios Android 11 o anteriores, el sistema también puede requerir ubicación para detectar adaptadores. Fotos y archivos se eligen mediante el selector del sistema. Mantener app activa es opcional y utiliza un servicio visible durante la sesión OBD.

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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/obd_provider.dart';
import '../providers/dash_settings_provider.dart';
import '../services/workshop_diagnostics.dart';

class WorkshopDiagnosticsPanel extends StatefulWidget {
  const WorkshopDiagnosticsPanel({super.key});

  @override
  State<WorkshopDiagnosticsPanel> createState() =>
      _WorkshopDiagnosticsPanelState();
}

class _WorkshopDiagnosticsPanelState extends State<WorkshopDiagnosticsPanel> {
  WorkshopReport? _report;
  WorkshopFreezeFrame? _freeze;
  String? _status;
  bool _busy = false;

  Future<void> _readFreeze() async {
    if (_busy) return;
    final diagnostics = WorkshopDiagnostics(context.read<ObdProvider>());
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final freeze = await diagnostics.readFreezeFrame(isActive: () => mounted);
      if (mounted) setState(() => _freeze = freeze);
    } catch (_) {
      if (mounted)
        setState(() => _status = 'No se pudo leer la captura de la falla.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run({bool clear = false}) async {
    if (_busy) return;
    if (clear) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Borrar códigos de emisiones?'),
          content: const Text(
            'Hazlo después de reparar la falla. El vehículo debe estar estacionado, con el motor apagado y el contacto encendido. También se reinician los datos congelados y los monitores de emisiones. Los códigos permanentes desaparecen cuando la centralita completa sus comprobaciones.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar códigos'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final diagnostics = WorkshopDiagnostics(context.read<ObdProvider>());
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final report = clear
          ? await diagnostics.clear(isActive: () => mounted)
          : await diagnostics.read(isActive: () => mounted);
      if (!mounted) return;
      setState(() {
        _report = report;
        if (clear) _freeze = null;
        _status = clear ? 'La centralita confirmó el borrado.' : null;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _status = error is StateError
              ? error.message
              : 'No se pudo completar el diagnóstico.';
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final freeze = _freeze;
    final settings = context.watch<DashSettingsProvider>();
    final connected = context.select(
      (ObdProvider obd) =>
          obd.isRealMode &&
          obd.isDeviceConnected &&
          obd.state == ObdConnectionState.ready,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          'Diagnóstico OBD II',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Motor y emisiones · la disponibilidad depende de la centralita y del adaptador.',
          style: TextStyle(color: AppColors.textSecondaryColor),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: !connected || _busy ? null : () => _run(),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('Leer códigos'),
            ),
            OutlinedButton.icon(
              onPressed: !connected || _busy || report?.confirmed == null
                  ? null
                  : () => _run(clear: true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Borrar códigos'),
            ),
            OutlinedButton.icon(
              onPressed: !connected || _busy ? null : _readFreeze,
              icon: const Icon(Icons.camera_outlined),
              label: const Text('Captura de la falla'),
            ),
          ],
        ),
        if (!connected)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Conecta el ELM en modo OBD II.'),
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_status!),
          ),
        if (freeze != null) ...[
          const Divider(height: 22),
          const Text(
            'Datos congelados',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          if (freeze.rpm == null &&
              freeze.speedKmh == null &&
              freeze.coolantC == null)
            const Text('La centralita no devolvió una captura.')
          else ...[
            if (freeze.rpm != null) Text('Motor: ${freeze.rpm} rpm'),
            if (freeze.speedKmh != null)
              Text(
                'Velocidad: ${settings.displaySpeed(freeze.speedKmh!).round()} ${settings.speedUnitLabel}',
              ),
            if (freeze.coolantC != null)
              Text(
                'Refrigerante: ${settings.convertTemp(freeze.coolantC!).round()} ${settings.tempUnit == TemperatureUnit.celsius ? '°C' : '°F'}',
              ),
          ],
        ],
        if (report != null) ...[
          const Divider(height: 24),
          if (report.adapter != null) Text(report.adapter!),
          Text(
            'Luz de motor: ${switch (report.mil) {
              true => 'encendida',
              false => 'apagada',
              null => 'sin lectura',
            }}',
          ),
          Text('Monitores pendientes: ${report.notReady ?? 'sin lectura'}'),
          if (report.supportedPids != null)
            Text('PIDs estándar disponibles (01–20): ${report.supportedPids}'),
          _Codes('Confirmados', report.confirmed),
          _Codes('Pendientes', report.pending),
          _Codes('Permanentes', report.permanent),
        ],
      ],
    );
  }
}

class _Codes extends StatelessWidget {
  const _Codes(this.title, this.codes);
  final String title;
  final Set<String>? codes;

  static const descriptions = {
    'P0171': 'Mezcla pobre · banco 1',
    'P0172': 'Mezcla rica · banco 1',
    'P0300': 'Fallos de encendido múltiples o aleatorios',
    'P0420': 'Eficiencia del catalizador por debajo del umbral · banco 1',
    'P0442': 'Fuga pequeña en el sistema de emisiones evaporativas',
  };

  @override
  Widget build(BuildContext context) {
    final values = codes;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          if (values == null)
            const Text('Sin lectura disponible')
          else if (values.isEmpty)
            const Text('Sin códigos')
          else
            for (final code in values)
              Text(
                descriptions[code] == null
                    ? code
                    : '$code · ${descriptions[code]}',
              ),
        ],
      ),
    );
  }
}

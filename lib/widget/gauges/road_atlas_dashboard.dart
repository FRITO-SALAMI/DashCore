import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../dashboard_brand_mark.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../core/app_colors.dart';
import '../../models/obd_data.dart';
import '../../providers/dash_settings_provider.dart';
import '../../providers/obd_provider.dart';
import '../../services/usb_gnss_reader.dart';
import '../dashboard_vehicle.dart';
import '../display_units.dart';
import '../vehicle_stage.dart';
import 'local_position_view.dart';
import 'offline_navigator.dart';

class RoadAtlasDashboard extends StatelessWidget {
  const RoadAtlasDashboard({
    super.key,
    required this.data,
    required this.source,
    this.preview = false,
    this.onGarage,
  });

  // Like the other legacy instrument widgets, data is already in display units.
  final ObdData data;
  final String source;
  final bool preview;
  final VoidCallback? onGarage;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final vehicle = settings.selectedVehicle;
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 300 || constraints.maxWidth < 590;
          final showInstruments =
              !preview &&
              constraints.maxWidth >= 760 &&
              constraints.maxHeight >= 260;
          return Row(
            textDirection: !preview && settings.roadAtlasVehicleOnRight
                ? TextDirection.rtl
                : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: compact ? 4 : 3,
                child: _RoadPanel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const DashboardBrandMark(width: 38),
                          const Spacer(),
                          if (onGarage != null)
                            IconButton(
                              tooltip: 'Abrir garaje',
                              onPressed: onGarage,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.directions_car_outlined,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: DashboardVehicle(
                          preview: preview,
                          colorHex: settings.vehicleColorHex,
                          vehicle: vehicle,
                        ),
                      ),
                      if (!preview && vehicle != null)
                        Text(
                          '${vehicle.brand} ${vehicle.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${data.speed}',
                                style: TextStyle(
                                  height: 1,
                                  fontSize: compact ? 38 : 69,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const SpeedUnitLabel(
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: _RoadPanel(
                  padding: EdgeInsets.zero,
                  child: preview
                      ? const _MapPlaceholder(label: 'MAPA EN VIVO')
                      : const _RoadMap(),
                ),
              ),
              if (showInstruments) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _RoadPanel(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SideReading(
                          Icons.speed_rounded,
                          'RPM',
                          data.rpm == 0 && source == 'SIN CONEXIÓN'
                              ? '—'
                              : '${data.rpm} rpm',
                        ),
                        _SideReading(
                          Icons.thermostat_outlined,
                          'TEMPERATURA',
                          data.engineTemp == 0 && source == 'SIN CONEXIÓN'
                              ? '—'
                              : '${settings.convertTemp(data.engineTemp).round()} ${settings.tempUnit == TemperatureUnit.celsius ? '°C' : '°F'}',
                        ),
                        _SideReading(
                          Icons.bolt_outlined,
                          'BATERÍA',
                          data.voltage <= 0
                              ? '—'
                              : '${data.voltage.toStringAsFixed(1)} V',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SideReading extends StatelessWidget {
  const _SideReading(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.accent, size: 18),
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondaryColor,
        ),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _RoadPanel extends StatelessWidget {
  const _RoadPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.hardEdge,
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF122731), Color(0xFF091219)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF254B5A)),
    ),
    child: child,
  );
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const LocalPositionView(trail: []),
      Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: AppColors.background,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _RoadMap extends StatefulWidget {
  const _RoadMap();

  @override
  State<_RoadMap> createState() => _RoadMapState();
}

class _RoadMapState extends State<_RoadMap> with WidgetsBindingObserver {
  Object? _locationSession;
  StreamSubscription<Position>? _positions;
  StreamSubscription<UsbEvent>? _usbEvents;
  UsbGnssReader? _usbReader;
  (UsbDevice, int)? _usbSource;
  String? _sourceError;
  ObdProvider? _obd;
  Position? _position;
  bool _enabled = false;
  bool _isForeground = true;
  bool _isCurrent = true;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _appActive = context.watch<DashSettingsProvider>().isAppActive;
    _updateActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android's USB permission dialog briefly makes the activity inactive.
    if (state == AppLifecycleState.inactive) return;
    _isForeground = state == AppLifecycleState.resumed;
    _updateActivity();
  }

  void _updateActivity() {
    if (!_enabled || !_isCurrent || !_isForeground || !_appActive) {
      _stop();
      return;
    }
    if (_positions != null || _usbReader != null) return;
    _locationSession = Object();
    final usb = _usbSource;
    if (usb != null) {
      final reader = UsbGnssReader();
      _usbReader = reader;
      _usbEvents = UsbSerial.usbEventStream?.listen((event) {
        if (event.event == UsbEvent.ACTION_USB_DETACHED &&
            event.device?.deviceName == usb.$1.deviceName) {
          _usbFailed(reader, 'El receptor GPS USB se desconectó.');
        }
      });
      unawaited(
        reader
            .start(
              usb.$1,
              usb.$2,
              _onPosition,
              () => _usbFailed(reader, 'Se perdió la señal del puerto USB.'),
            )
            .catchError((Object error) {
              _usbFailed(
                reader,
                error is StateError
                    ? error.message
                    : 'No se pudo abrir el GPS USB.',
              );
            }),
      );
      return;
    }
    final obd = context.read<ObdProvider>();
    _obd = obd;
    _positions = obd.gpsPositions.listen(_onPosition);
    final last = obd.lastGpsPosition;
    if (last != null &&
        DateTime.now().difference(last.timestamp) <
            const Duration(seconds: 20)) {
      _onPosition(last);
    }
    final clientAtStart = _locationSession;
    unawaited(
      obd.acquireVisualLocation().then((ready) {
        if (!mounted || ready || !identical(_locationSession, clientAtStart))
          return;
        _stop();
        setState(() {
          _enabled = false;
          _sourceError =
              'Activa la ubicación y permite su uso para ver el mapa.';
        });
      }),
    );
  }

  void _usbFailed(UsbGnssReader reader, String message) {
    if (!mounted || !identical(_usbReader, reader)) return;
    _stop();
    setState(() {
      _enabled = false;
      _sourceError = message;
    });
  }

  Future<void> _selectUsb() async {
    try {
      final devices = await UsbSerial.listDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() => _sourceError = 'Conecta un receptor GPS NMEA por USB.');
        return;
      }
      UsbDevice device = devices.first;
      var baud = 9600;
      final selection = await showDialog<(UsbDevice, int)>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: const Text('GPS USB'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<UsbDevice>(
                  isExpanded: true,
                  value: device,
                  items: devices
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value.productName ?? value.deviceName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) update(() => device = value);
                  },
                ),
                DropdownButton<int>(
                  value: baud,
                  items: [4800, 9600, 38400, 115200]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value baudios'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) update(() => baud = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, (device, baud)),
                child: const Text('Conectar'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || selection == null) return;
      _stop();
      setState(() {
        _usbSource = selection;
        _sourceError = null;
        _enabled = true;
      });
      _updateActivity();
    } catch (_) {
      if (mounted)
        setState(() => _sourceError = 'No se pudo consultar el puerto USB.');
    }
  }

  void _onPosition(Position position) {
    if (!mounted ||
        (_positions == null && _usbReader == null) ||
        !position.latitude.isFinite ||
        position.latitude.abs() > 90 ||
        !position.longitude.isFinite ||
        position.longitude.abs() > 180 ||
        !position.accuracy.isFinite ||
        position.accuracy > 50)
      return;
    setState(() => _position = position);
  }

  void _stop() {
    unawaited(_usbEvents?.cancel());
    _usbEvents = null;
    unawaited(_usbReader?.close());
    _usbReader = null;
    unawaited(_positions?.cancel());
    _positions = null;
    _obd?.releaseVisualLocation();
    _obd = null;
    _locationSession = null;
    _position = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OfflineNavigator(
    position: _position,
    sourceError: _sourceError,
    enabled: _enabled,
    onGps: () {
      if (_enabled && _usbSource == null && _positions != null) return;
      _stop();
      setState(() {
        _enabled = true;
        _usbSource = null;
        _sourceError = null;
      });
      _updateActivity();
    },
    onUsb: _selectUsb,
  );
}

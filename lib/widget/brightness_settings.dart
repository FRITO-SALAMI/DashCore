import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two daily boundaries cover the entire day, including overnight intervals.
double scheduledBrightness(
  int minute,
  int start,
  int end,
  double day,
  double night,
) {
  final inside = start < end
      ? minute >= start && minute < end
      : minute >= start || minute < end;
  return inside ? day : night;
}

class _Brightness extends ChangeNotifier {
  static final instance = _Brightness();
  static const channel = MethodChannel('io.dashcore.app/launcher');
  bool enabled = false, scheduled = false;
  int start = 420, end = 1140;
  double manual = 70, day = 90, night = 25;
  late final Future<void> ready = load();
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool('brightness_enabled') ?? false;
    scheduled = p.getBool('brightness_scheduled') ?? false;
    start = p.getInt('brightness_start') ?? 420;
    end = p.getInt('brightness_end') ?? 1140;
    manual = p.getDouble('brightness_manual') ?? 70;
    day = p.getDouble('brightness_day') ?? 90;
    night = p.getDouble('brightness_night') ?? 25;
    notifyListeners();
  }

  Future<void> save() async {
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setBool('brightness_enabled', enabled),
      p.setBool('brightness_scheduled', scheduled),
      p.setInt('brightness_start', start),
      p.setInt('brightness_end', end),
      p.setDouble('brightness_manual', manual),
      p.setDouble('brightness_day', day),
      p.setDouble('brightness_night', night),
    ]);
  }

  double get value {
    if (!enabled) return -1;
    final now = DateTime.now();
    return (scheduled
            ? scheduledBrightness(
                now.hour * 60 + now.minute,
                start,
                end,
                day,
                night,
              )
            : manual) /
        100;
  }
}

class BrightnessRuntime extends StatefulWidget {
  final Widget child;
  const BrightnessRuntime({super.key, required this.child});
  @override
  State<BrightnessRuntime> createState() => _BrightnessRuntimeState();
}

class _BrightnessRuntimeState extends State<BrightnessRuntime>
    with WidgetsBindingObserver {
  final config = _Brightness.instance;
  Timer? timer;
  double? applied;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    config.addListener(apply);
    config.ready.then((_) {
      if (mounted) {
        apply();
        schedule();
      }
    });
  }

  void schedule() {
    timer?.cancel();
    final now = DateTime.now();
    timer = Timer(
      Duration(milliseconds: 60000 - now.second * 1000 - now.millisecond),
      () {
        apply();
        schedule();
      },
    );
  }

  Future<void> apply() async {
    final value = config.value;
    if (applied == value) return;
    try {
      await _Brightness.channel.invokeMethod('setWindowBrightness', {
        'value': value,
      });
      applied = value;
    } on PlatformException catch (e) {
      debugPrint('Brightness: $e');
    } on MissingPluginException {
      /* Non-Android preview. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      applied = null;
      apply();
      schedule();
    } else {
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    config.removeListener(apply);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class BrightnessSettings extends StatefulWidget {
  const BrightnessSettings({super.key});
  @override
  State<BrightnessSettings> createState() => _BrightnessSettingsState();
}

class _BrightnessSettingsState extends State<BrightnessSettings> {
  final config = _Brightness.instance;
  @override
  void initState() {
    super.initState();
    config.ready.then((_) {
      if (mounted) setState(() {});
    });
  }

  void change(VoidCallback update) {
    setState(update);
    config.save();
  }

  String time(int minute) =>
      context.read<DashSettingsProvider>().formatTime(minute ~/ 60, minute % 60);
  Future<void> pick(bool first) async {
    final minutes = first ? config.start : config.end;
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (result == null || !mounted) return;
    final value = result.hour * 60 + result.minute;
    if (value == (first ? config.end : config.start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige dos horas diferentes.')),
      );
      return;
    }
    change(() {
      if (first) {
        config.start = value;
      } else {
        config.end = value;
      }
    });
  }

  Widget slider(String label, double value, ValueChanged<double> update) =>
      Column(
        children: [
          Text(
            '$label: ${value.round()}%',
            style: const TextStyle(color: Colors.white),
          ),
          Slider(
            value: value,
            min: 5,
            max: 100,
            divisions: 95,
            label: '${value.round()}%',
            onChanged: (v) => change(() => update(v)),
          ),
        ],
      );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile(
        title: const Text('BRILLO DE DASHCORE'),
        subtitle: const Text('Controla el brillo mientras usas la app'),
        value: config.enabled,
        onChanged: (v) => change(() => config.enabled = v),
      ),
      if (config.enabled) ...[
        SwitchListTile(
          title: const Text('POR HORARIO'),
          subtitle: const Text('Desactivado: brillo manual'),
          value: config.scheduled,
          onChanged: (v) => change(() => config.scheduled = v),
        ),
        if (!config.scheduled)
          slider('Brillo manual', config.manual, (v) => config.manual = v),
        if (config.scheduled) ...[
          ListTile(
            title: Text('Desde ${time(config.start)}'),
            trailing: const Icon(Icons.schedule),
            onTap: () => pick(true),
          ),
          ListTile(
            title: Text('Hasta ${time(config.end)}'),
            trailing: const Icon(Icons.schedule),
            onTap: () => pick(false),
          ),
          slider('Brillo en este horario', config.day, (v) => config.day = v),
          slider(
            'Brillo el resto del día',
            config.night,
            (v) => config.night = v,
          ),
        ],
      ],
    ],
  );
}

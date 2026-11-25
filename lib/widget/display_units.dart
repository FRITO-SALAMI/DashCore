import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';

String speedUnitOf(BuildContext context) =>
    context.watch<DashSettingsProvider?>()?.speedUnitLabel ?? 'KM/H';
String distanceUnitOf(BuildContext context) =>
    context.watch<DashSettingsProvider?>()?.distanceUnitLabel ?? 'KM';

class SpeedUnitLabel extends StatelessWidget {
  final TextStyle? style;
  final TextAlign? textAlign;
  const SpeedUnitLabel({super.key, this.style, this.textAlign});
  @override
  Widget build(BuildContext context) => Text(speedUnitOf(context), style: style, textAlign: textAlign);
}

class DashboardClock extends StatefulWidget {
  final TextStyle? style;
  const DashboardClock({super.key, this.style});
  @override
  State<DashboardClock> createState() => _DashboardClockState();
}
class _DashboardClockState extends State<DashboardClock> {
  Timer? timer;
  @override
  void initState() { super.initState(); schedule(); }
  void schedule() {
    final now = DateTime.now();
    timer = Timer(Duration(milliseconds: 60000 - now.second * 1000 - now.millisecond), () {
      if (!mounted) return;
      setState(() {});
      schedule();
    });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final settings = context.watch<DashSettingsProvider>();
    return Text(settings.formatTime(now.hour, now.minute), style: widget.style);
  }
}

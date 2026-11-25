import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashcore/widget/brightness_settings.dart';
import 'package:dashcore/widget/compatible_vehicle_model.dart';
import 'package:dashcore/widget/dashboard_limit_alerts.dart';
import 'package:dashcore/models/obd_data.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/providers/music_provider.dart';
import 'package:dashcore/widget/music_hub.dart';
import 'package:provider/provider.dart';

class AlertSettings implements DashSettingsProvider {
  @override
  bool get tempWarningEnabled => true;
  @override
  bool get speedWarningEnabled => true;
  @override
  double get tempAlertThreshold => 105;
  @override
  double get speedAlertThreshold => 120;
  @override
  double displaySpeed(num kmh) => kmh.toDouble();
  @override
  double get displaySpeedAlertThreshold => speedAlertThreshold;
  @override
  String get speedUnitLabel => 'KM/H';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Brightness switches at both boundaries and wraps midnight', () {
    expect(scheduledBrightness(419, 420, 1140, 90, 25), 25);
    expect(scheduledBrightness(420, 420, 1140, 90, 25), 90);
    expect(scheduledBrightness(1140, 420, 1140, 90, 25), 25);
    expect(scheduledBrightness(30, 1140, 420, 25, 90), 25);
    expect(scheduledBrightness(420, 1140, 420, 25, 90), 90);
  });
  test('Downloaded GLB paths are file URLs, assets and HTTPS remain valid', () {
    expect(
      vehicleModelSource('/storage/emulated/0/My Car.glb'),
      'file:///storage/emulated/0/My%20Car.glb',
    );
    expect(vehicleModelSource('assets/car.glb'), 'assets/car.glb');
    expect(
      vehicleModelSource('https://example.com/car.glb'),
      'https://example.com/car.glb',
    );
  });
  testWidgets('Hybrid viewer bundles WebGL 2 and WebGL 1 fallback', (
    tester,
  ) async {
    final html = await rootBundle.loadString('assets/web/three/viewer.html');
    expect(html, contains("getContext('webgl2'"));
    expect(html, contains("getContext('webgl'"));
    expect(html, contains('THREE.GLTFLoader'));
    expect(html, contains('THREE.DRACOLoader'));
    expect(html, contains('loader.setDRACOLoader(draco)'));
    expect(html, contains('categoryForMaterial'));
    for (final group in [
      'carroceria',
      'cristales',
      'cromadosdetalles',
      'interior',
      'ruedasneumaticos',
      'mecanismos',
    ]) {
      expect(html, contains("name === '$group'"));
    }
    expect(
      html,
      contains('node.material.map(function (m) { return m.clone(); })'),
    );
    expect(html, contains('window.updateDashcoreColor'));
    expect(html, contains('window.disposeDashcore = dispose'));
  });
  testWidgets('Both limits appear at the exact threshold and clear below it', (
    tester,
  ) async {
    Future<void> show(ObdData data) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardLimitAlerts(data: data, settings: AlertSettings()),
        ),
      ),
    );
    await show(const ObdData(speed: 120, engineTemp: 105));
    expect(find.textContaining('VELOCIDAD 120'), findsOneWidget);
    expect(find.textContaining('TEMPERATURA 105'), findsOneWidget);
    await show(const ObdData(speed: 119, engineTemp: 104));
    expect(find.textContaining('LÍMITE'), findsNothing);
  });
  testWidgets('Every mounted music hub follows native metadata and controls', (
    tester,
  ) async {
    final calls = <String>[];
    const launcher = MethodChannel('io.dashcore.app/launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, (
      call,
    ) async {
      if (call.method == 'mediaControl') {
        calls.add(call.arguments['command'] as String);
      }
      return null;
    });
    final music = MusicProvider();
    Future<void> native(String method, Map<String, dynamic> args) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'io.dashcore.app/media_updates',
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
        (_) {},
      );
      await tester.pump();
    }

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: music,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(children: [MusicHub(), MusicHub(compact: true)]),
          ),
        ),
      ),
    );
    await native('onMetadataChanged', {
      'title': 'Pista local',
      'artist': 'Artista',
    });
    await native('onPlaybackStateChanged', {
      'isPlaying': true,
      'position': 1000,
      'duration': 10000,
    });
    expect(find.text('Pista local'), findsNWidgets(2));
    expect(find.byIcon(Icons.pause_rounded), findsNWidgets(2));
    expect(music.progress, 0.1);
    await native('onPlaybackStateChanged', {'isPlaying': false});
    expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(2));
    expect(music.progress, greaterThanOrEqualTo(0.1));
    await native('onPlaybackStateChanged', {'isPlaying': true});
    await tester.tap(find.byIcon(Icons.skip_next_rounded).first);
    expect(calls, ['next']);
    await native('onMetadataChanged', {'title': ''});
    expect(find.text('SIN MÚSICA'), findsNWidgets(2));
    expect(music.isPlaying, false);
    await tester.pumpWidget(const SizedBox.shrink());
    music.dispose();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      launcher,
      null,
    );
  });

  testWidgets('A narrow music gadget keeps its controls inside its bounds', (
    tester,
  ) async {
    const launcher = MethodChannel('io.dashcore.app/launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      launcher,
      (_) async => null,
    );
    final music = MusicProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: music,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              height: 40,
              child: MusicHub(compact: true),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    music.dispose();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      launcher,
      null,
    );
  });
}

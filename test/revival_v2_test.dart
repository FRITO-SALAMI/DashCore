import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashcore/screens/connect_screen.dart';
import 'package:dashcore/screens/store_screen.dart';
import 'package:dashcore/providers/obd_provider.dart';
import 'package:dashcore/widget/connection/obd_connection_help.dart';
import 'package:dashcore/widget/compatible_vehicle_model.dart';
import 'package:dashcore/widget/vehicle_stage.dart';
import 'package:dashcore/models/vehicle_model.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:dashcore/services/resource_service.dart';
import 'package:dashcore/services/supabase_service.dart';
import 'package:dashcore/widget/gauges/instrument_cluster_v2.dart';
import 'package:dashcore/widget/gauges/local_position_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/providers/music_provider.dart';
import 'package:dashcore/widget/gauges/night_drive_dashboard.dart';
import 'package:dashcore/models/obd_data.dart';
import 'package:dashcore/services/glb_inspector.dart';
import 'package:dashcore/services/gps_simulation.dart';

class PreviewSettings implements DashSettingsProvider {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  get selectedVehicle => null;
  @override
  String get modelPath => '';
  @override
  bool get reduceMotion => true;
  @override
  String get speedUnitLabel => 'KM/H';
  @override
  double displaySpeed(num kmh) => kmh.toDouble();
  @override
  Color get accentColor => const Color(0xFF00E5FF);
  @override
  bool get useSimulatedFuel => false;
  @override
  Language get language => Language.spanish;
  @override
  bool get isTutorialActive => false;
  @override
  bool get isLoggedIn => false;
  @override
  DashboardStyle get selectedStyle => DashboardStyle.nightDrive;
  @override
  Set<DashboardStyle> get downloadedStyles => {
    DashboardStyle.sporty,
    DashboardStyle.nightDrive,
  };
  @override
  TemperatureUnit get tempUnit => TemperatureUnit.celsius;
  @override
  double convertTemp(int value) => value.toDouble();
  @override
  String formatTime(int hour, int minute) => '8:45';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DisconnectedObd extends ChangeNotifier implements ObdProvider {
  @override
  bool get isRealMode => false;
  @override
  bool get isGpsMode => false;
  @override
  bool get isDeviceConnected => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StoreSettings extends PreviewSettings {
  DashboardStyle? applied;
  @override
  void setStyle(DashboardStyle style) {
    applied = style;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final size in [
    const Size(640, 360),
    const Size(800, 480),
    const Size(1024, 600),
  ]) {
    for (final design in ClusterDesign.values) {
      testWidgets(
        '${design.name} fits ${size.width.toInt()}x${size.height.toInt()} with large text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(1.3),
                ),
                child: const Scaffold(body: SizedBox()),
              ),
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: InstrumentClusterV2(
                    speed: 86,
                    rpm: 2800,
                    coolantTemp: 91,
                    voltage: 13.8,
                    design: design,
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.text('86'), findsOneWidget);
          expect(find.text('13.8'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'Vehicle stage follows the owner selection and opens the garage',
    (tester) async {
      var opens = 0;
      Widget stage(String id, String name) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 280,
            child: VehicleStage(
              vehicle: Vehicle(
                id: id,
                name: name,
                brand: 'Mi marca',
                backgroundImage: '',
                modelPath: '',
                isCustom: true,
              ),
              modelPath: '',
              reduceMotion: true,
              onChangeVehicle: () => opens++,
            ),
          ),
        ),
      );
      await tester.pumpWidget(stage('custom_one', 'Mi primer auto'));
      expect(find.text('MI MARCA MI PRIMER AUTO'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await tester.tap(find.text('MI VEHÍCULO'));
      expect(opens, 1);
      await tester.pumpWidget(stage('custom_two', 'Mi segundo auto'));
      expect(find.text('MI MARCA MI PRIMER AUTO'), findsNothing);
      expect(find.text('MI MARCA MI SEGUNDO AUTO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Night Drive is the initial style and a saved choice survives relaunch',
    () async {
      SharedPreferences.setMockInitialValues({});
      final fresh = DashSettingsProvider();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fresh.selectedStyle, DashboardStyle.nightDrive);
      fresh.dispose();
      SharedPreferences.setMockInitialValues({
        'selected_style_idx': DashboardStyle.modern.index,
      });
      final returning = DashSettingsProvider();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(returning.selectedStyle, DashboardStyle.modern);
      returning.dispose();
    },
  );

  testWidgets(
    'Night Drive is first in the store with a complete static preview',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = _StoreSettings();
      await tester.pumpWidget(
        ChangeNotifierProvider<DashSettingsProvider>.value(
          value: settings,
          child: MaterialApp(home: StoreScreen(onBack: () {})),
        ),
      );
      await tester.pump();
      expect(find.text('NIGHT DRIVE 2.0'), findsOneWidget);
      expect(find.byType(NightDrivePreview), findsOneWidget);
      expect(find.byType(CompatibleVehicleModel), findsNothing);
      final preview = find.byType(NightDrivePreview);
      expect(
        find.descendant(of: preview, matching: find.text('86')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: preview, matching: find.text('13.8')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('NIGHT DRIVE 2.0')).dx,
        lessThan(tester.getTopLeft(find.text('RACING PRO')).dx),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('NIGHT DRIVE 2.0'));
      expect(settings.applied, DashboardStyle.nightDrive);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Multiple Night Drive thumbnails do not register tutorial targets',
    (tester) async {
      final settings = PreviewSettings();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(child: NightDrivePreview(settings: settings)),
                Expanded(child: NightDrivePreview(settings: settings)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('13.8'), findsNWidgets(2));
      expect(find.text('VISTA PREVIA'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OBD help opens from connection screen and stays scrollable on a small radio',
    (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final obd = _DisconnectedObd();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DashSettingsProvider>.value(
              value: PreviewSettings(),
            ),
            ChangeNotifierProvider<ObdProvider>.value(value: obd),
          ],
          child: MaterialApp(home: ConnectionScreen(onBack: () {})),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Ayuda para conectar OBD2'));
      await tester.pumpAndSettle();
      expect(find.byType(ObdConnectionHelpDialog), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.byIcon(Icons.settings_bluetooth_rounded), findsOneWidget);
      expect(
        find.textContaining('Si tu radio permite cambiar'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('5. Regresa a DashCore'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('ENTENDIDO'));
      await tester.pumpAndSettle();
      expect(find.byType(ObdConnectionHelpDialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      obd.dispose();
    },
  );

  testWidgets('Unavailable engine readings can be hidden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InstrumentClusterV2(
            speed: 42,
            rpm: 2800,
            coolantTemp: 91,
            voltage: 13.8,
            engineAvailable: false,
          ),
        ),
      ),
    );
    expect(find.text('42'), findsOneWidget);
    expect(find.text('13.8'), findsNothing);
    expect(find.text('91'), findsNothing);
    expect(find.text('2800'), findsNothing);
    expect(find.text('GPS · LOCAL'), findsOneWidget);
  });

  test(
    'No-OBD simulation preserves exact GPS speed and changes engine values smoothly',
    () {
      final simulation = GpsSimulation();
      final start = DateTime.utc(2026, 11, 4);
      final first = simulation.sample(42, start);
      final next = simulation.sample(42, start.add(const Duration(seconds: 1)));
      expect(first.speed, 42);
      expect(next.speed, 42);
      expect((next.voltage - first.voltage).abs(), lessThan(.1));
      expect(next.engineTemp, inInclusiveRange(82, 92));
      expect(
        simulation
            .sample(42, start.add(const Duration(minutes: 10)))
            .engineTemp,
        92,
      );
    },
  );

  test(
    'GLB inspector rejects truncated and external-resource models before a WebView loads',
    () async {
      final directory = await Directory.systemTemp.createTemp('dashcore-glb-');
      addTearDown(() => directory.delete(recursive: true));
      Future<File> model(
        Map<String, dynamic> metadata, {
        int version = 2,
      }) async {
        List<int> json = utf8.encode(jsonEncode(metadata));
        while (json.length % 4 != 0) {
          json = [...json, 32];
        }
        final bytes = Uint8List(20 + json.length);
        bytes.setRange(0, 4, ascii.encode('glTF'));
        final header = ByteData.sublistView(bytes);
        header.setUint32(4, version, Endian.little);
        header.setUint32(8, bytes.length, Endian.little);
        header.setUint32(12, json.length, Endian.little);
        header.setUint32(16, 0x4e4f534a, Endian.little);
        bytes.setRange(20, bytes.length, json);
        return File('${directory.path}/model.glb').writeAsBytes(bytes);
      }

      final safe = await model({
        'asset': {'version': '2.0'},
        'accessors': [
          {'count': 210000},
        ],
        'meshes': [
          {
            'primitives': [
              {
                'attributes': {'POSITION': 0},
              },
            ],
          },
        ],
      });
      expect((await inspectGlb(safe)).expensive, true);
      final external = await model({
        'buffers': [
          {'uri': 'https://example.com/track'},
        ],
      });
      await expectLater(inspectGlb(external), throwsFormatException);
      final old = await model({}, version: 1);
      await expectLater(inspectGlb(old), throwsFormatException);
    },
  );

  test('Local trail discards old points and inaccurate GPS samples', () {
    final trail = LocalTrail();
    Position point(int i, {double accuracy = 5}) => Position(
      longitude: -69.9 + i / 100000,
      latitude: 18.4,
      timestamp: DateTime.utc(2026, 11, 4).add(Duration(seconds: i)),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 90,
      headingAccuracy: 1,
      speed: 10,
      speedAccuracy: 1,
    );
    for (var i = 0; i < 500; i++) {
      trail.add(point(i));
    }
    expect(trail.positions.length, 180);
    final last = trail.positions.last;
    trail.add(point(501, accuracy: 150));
    expect(trail.positions.last, last);
    trail.clear();
    expect(trail.positions, isEmpty);
  });

  test('ZIP packs extract from disk and reject traversal before writing', () {
    final dir = Directory.systemTemp.createTempSync('dashcore-pack-test-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final zip = File('${dir.path}/pack.zip');
    final archive = Archive()
      ..addFile(ArchiveFile('nested/sound.txt', 3, [1, 2, 3]));
    zip.writeAsBytesSync(ZipEncoder().encode(archive));
    extractResourcePack([zip.path, '${dir.path}/output']);
    expect(File('${dir.path}/output/nested/sound.txt').readAsBytesSync(), [
      1,
      2,
      3,
    ]);
    final bad = Archive()..addFile(ArchiveFile('../outside.txt', 1, [1]));
    zip.writeAsBytesSync(ZipEncoder().encode(bad));
    expect(
      () => extractResourcePack([zip.path, '${dir.path}/other']),
      throwsFormatException,
    );
    expect(File('${dir.path}/outside.txt').existsSync(), false);
  });

  test('Secure session storage returns the full refreshable session', () async {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final values = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final key = call.arguments['key'] as String;
          switch (call.method) {
            case 'write':
              values[key] = call.arguments['value'] as String;
              return null;
            case 'read':
              return values[key];
            case 'delete':
              values.remove(key);
              return null;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final storage = SecureLocalStorage();
    const session = '{"access_token":"access","refresh_token":"refresh"}';
    await storage.persistSession(session);
    expect(await storage.accessToken(), session);
    expect(values.keys.single, contains('znrxgcfdvsmqkvejyrbo'));
    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), false);
  });

  testWidgets('export design previews for visual review', (tester) async {
    tester.view.physicalSize = const Size(960, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    for (final design in [
      ClusterDesign.sport,
      ClusterDesign.modern,
      ClusterDesign.racing,
      ClusterDesign.retro,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: InstrumentClusterV2(
                speed: 86,
                rpm: 2800,
                coolantTemp: 91,
                voltage: 13.8,
                design: design,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File('docs/screenshots/v2-${design.name}.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'Night Drive reproduces the reference and keeps exact instrument values',
    (tester) async {
      const channel = MethodChannel('io.dashcore.app/launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      final music = MusicProvider();
      final settings = PreviewSettings();
      final key = GlobalKey();
      tester.view.physicalSize = const Size(1120, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MusicProvider>.value(value: music),
            ChangeNotifierProvider<DashSettingsProvider>.value(value: settings),
          ],
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: NightDriveDashboard(
                  data: const ObdData(
                    speed: 42,
                    rpm: 2000,
                    engineTemp: 83,
                    voltage: 13.8,
                  ),
                  settings: settings,
                  sourceLabel: 'OBD II',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('2000'), findsNothing);
      expect(find.text('13.8'), findsOneWidget);
      expect(find.text('Voltaje batería'), findsOneWidget);
      final speedText = tester.widget<Text>(find.text('42'));
      final tempText = tester.widget<Text>(find.text('83'));
      expect(speedText.style!.fontSize!, greaterThanOrEqualTo(80));
      expect(
        speedText.style!.fontSize!,
        greaterThan(tempText.style!.fontSize!),
      );
      expect(find.text('83'), findsOneWidget);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/screenshots/v2-night-drive.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.byTooltip('Reproducir'));
      await tester.pump();
      expect(find.byTooltip('Pausar'), findsOneWidget);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [
        const Size(640, 360),
        const Size(800, 480),
        const Size(1024, 600),
      ]) {
        tester.view.physicalSize = size;
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      music.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
}

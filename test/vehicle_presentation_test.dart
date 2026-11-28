import 'dart:io';
import 'dart:ui' as ui;
import 'package:dashcore/models/vehicle_model.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/utils/vehicle_presentation.dart';
import 'package:dashcore/widget/dashboard_vehicle.dart';
import 'package:dashcore/widget/compatible_vehicle_model.dart';
import 'package:dashcore/widget/realistic_vehicle_body.dart';
import 'package:dashcore/widget/vehicle_top_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'revival_v2_test.dart' show PreviewSettings;

class _LegacyModelSettings extends PreviewSettings {
  @override
  String get modelPath => 'assets/old-optima.glb';
}

void main() {
  test(
    'Optima generations have distinct names and catalog duplicates collapse',
    () {
      const older = Vehicle(
        id: 'local-k5',
        name: 'Optima',
        brand: 'Kia',
        year: '2012',
        backgroundImage: '',
        modelPath: '',
      );
      const newer = Vehicle(
        id: 'local-optima',
        name: 'Optima',
        brand: 'Kia',
        year: '2015',
        backgroundImage: '',
        modelPath: '',
      );
      const remote = Vehicle(
        id: 'remote-k5',
        name: 'Optima',
        brand: 'Kia',
        backgroundImage: '',
        modelPath: 'https://example.com/optima2012.glb',
      );
      final choices = uniqueVehicleChoices([older, newer], [remote], null);
      expect(choices.length, 2);
      expect(
        choices.map(vehicleDisplayName),
        containsAll(['Kia K5 / Optima TF · 2012', 'Kia Optima · 2015']),
      );
      expect(
        uniqueVehicleChoices([older, newer], [remote], older).first.id,
        older.id,
      );
    },
  );
  testWidgets('A saved GLB never replaces the new default car without opt-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DashSettingsProvider>.value(
        value: _LegacyModelSettings(),
        child: const MaterialApp(home: Scaffold(body: DashboardVehicle())),
      ),
    );
    expect(find.byType(VehicleTopView), findsOneWidget);
    expect(find.byType(CompatibleVehicleModel), findsNothing);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Vehicle fills the loose vertical constraints used by Apex GT and Carbon Pulse',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700,
                height: 300,
                child: Row(children: [Expanded(child: DashboardVehicle())]),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(RealisticVehicleBody)).height, 300);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Realistic body keeps glass neutral while paint changes and lights fade',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      Widget car(String shape, Color color, double lights) => SizedBox(
        width: 210,
        height: 370,
        child: RealisticVehicleBody(
          shape: shape,
          color: color,
          lighting: lights,
          hoodOpen: false,
          lowResource: true,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF071018),
            body: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFF071018),
                child: Wrap(
                  children: [
                    car('optima_2015', Colors.white, 0),
                    car('optima_2015', const Color(0xFFCC343F), 1),
                    car('k5_2012', const Color(0xFF187CB5), 1),
                    car('sonata_lf', Colors.white, 1),
                    car('generic', const Color(0xFFD5AC52), 1),
                    car('sonata_y20', const Color(0xFF1D897B), 1),
                    car('sonata_n', Colors.white, 1),
                    car('civic', const Color(0xFFCC343F), 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final raw = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        // A point on each Optima hood: white paint must be neutral, red paint remains red.
        List<int> pixel(int x, int y) {
          final i = (y * image.width + x) * 4;
          return [raw.getUint8(i), raw.getUint8(i + 1), raw.getUint8(i + 2)];
        }

        final white = pixel(105, 92),
            red = pixel(315, 92),
            glass = pixel(105, 135);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'E:/dashcore/Temp/dashcore-realistic-vehicles-qa.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        debugPrint('PAINT pixels white=$white red=$red glass=$glass');
        expect((white[0] - white[1]).abs(), lessThan(15));
        expect(red[0], greaterThan(red[1] * 1.4));
        expect(glass[0], lessThan(110));
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

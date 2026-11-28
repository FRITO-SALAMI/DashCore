import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dashcore/models/vehicle_model.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';
import 'package:dashcore/screens/car_screen.dart';
import 'package:dashcore/widget/vehicle_top_view.dart';
import 'revival_v2_test.dart' show PreviewSettings;

class _GarageSettings extends PreviewSettings {
  @override
  List<Vehicle> get availableVehicles => [];
}

void main() {
  testWidgets(
    'Garage opens on an engine view and keeps controls inside a small radio',
    (tester) async {
      final font = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      tester.view.physicalSize = const Size(1000, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider<DashSettingsProvider>.value(
          value: _GarageSettings(),
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'),
            ),
            home: RepaintBoundary(
              key: key,
              child: CarScreen(onBack: () {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.widget<VehicleTopView>(find.byType(VehicleTopView)).hoodOpen,
        isTrue,
      );
      expect(find.text('GARAJE'), findsOneWidget);
      expect(find.text('Encender luces'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'E:/dashcore/Temp/dashcore-101-garage.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      tester.view.physicalSize = const Size(640, 360);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

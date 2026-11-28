import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/dash_settings_provider.dart';
import 'vehicle_top_view.dart';
import '../services/glb_inspector.dart';

enum Loading { eager, lazy }

String vehicleModelSource(String source) =>
    source.startsWith('/') ? Uri.file(source).toString() : source;

class _ModelSource {
  const _ModelSource(this.modelUrl, this.viewerUrl, [this.profile]);
  final String modelUrl;
  final String viewerUrl;
  final GlbProfile? profile;
}

class _LocalThreeServer {
  _LocalThreeServer._();
  static final instance = _LocalThreeServer._();

  final Map<String, File> _files = {};
  final Map<String, String> _assets = {};
  HttpServer? _server;
  Future<void>? _starting;

  Future<void> _start() {
    if (_server != null) return Future.value();
    return _starting ??= _bind();
  }

  Future<void> _bind() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(_serve(_server!));
    } finally {
      _starting = null;
    }
  }

  void release(String url) {
    final token = Uri.tryParse(url)?.pathSegments.firstOrNull;
    _files.remove(token);
    _assets.remove(token);
  }

  Future<String> viewerUrl() async {
    await _start();
    return 'http://127.0.0.1:${_server!.port}/viewer.html';
  }

  Future<String> exposeFile(File file) async {
    final normalized = File(file.absolute.path);
    if (!await normalized.exists()) {
      throw const FileSystemException('El modelo descargado no existe');
    }
    await _validate(
      await normalized
          .openRead(0, 4)
          .fold<List<int>>(<int>[], (all, bytes) => all..addAll(bytes)),
      await normalized.length(),
    );
    await _start();
    final token = _token();
    _files[token] = normalized;
    return _modelUrl(token);
  }

  Future<String> exposeAsset(String path) async {
    final data = await rootBundle.load(path);
    await _validate(data.buffer.asUint8List(0, 4), data.lengthInBytes);
    await _start();
    final token = _token();
    _assets[token] = path;
    return _modelUrl(token);
  }

  Future<void> _validate(List<int> header, int length) async {
    if (length < 20) {
      throw const FormatException('El archivo GLB está vacío o incompleto');
    }
    if (String.fromCharCodes(header) != 'glTF') {
      throw const FormatException('El archivo no es un GLB válido');
    }
  }

  String _token() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
  String _modelUrl(String token) =>
      'http://127.0.0.1:${_server!.port}/$token/model.glb';

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      try {
        final staticPath = switch (request.uri.path) {
          '/viewer.html' => 'assets/web/three/viewer.html',
          '/three.min.js' => 'assets/web/three/three.min.js',
          '/GLTFLoader.js' => 'assets/web/three/GLTFLoader.js',
          '/DRACOLoader.js' => 'assets/web/three/DRACOLoader.js',
          '/draco/draco_decoder.js' => 'assets/web/three/draco_decoder.js',
          '/OrbitControls.js' => 'assets/web/three/OrbitControls.js',
          _ => null,
        };
        if (staticPath != null) {
          final data = await rootBundle.load(staticPath);
          request.response.headers.contentType =
              request.uri.path.endsWith('.js')
              ? ContentType('application', 'javascript', charset: 'utf-8')
              : ContentType.html;
          request.response.headers.set(
            'Cache-Control',
            'public, max-age=86400',
          );
          request.response.contentLength = data.lengthInBytes;
          request.response.add(data.buffer.asUint8List());
          await request.response.close();
          continue;
        }

        final token = request.uri.pathSegments.firstOrNull;
        final file = token == null ? null : _files[token];
        final asset = token == null ? null : _assets[token];
        request.response.headers.contentType = ContentType(
          'model',
          'gltf-binary',
        );
        request.response.headers.set('Cache-Control', 'no-store');
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        if (file != null && await file.exists()) {
          request.response.contentLength = await file.length();
          await request.response.addStream(file.openRead());
        } else if (asset != null) {
          final data = await rootBundle.load(asset);
          request.response.contentLength = data.lengthInBytes;
          request.response.add(data.buffer.asUint8List());
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      } catch (_) {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      }
    }
  }
}

class CompatibleVehicleModel extends StatefulWidget {
  const CompatibleVehicleModel({
    super.key,
    required this.src,
    this.backgroundColor = Colors.transparent,
    this.alt,
    this.autoRotate = false,
    this.cameraControls = true,
    this.disableZoom = true,
    this.disablePan = true,
    this.cameraOrbit,
    this.exposure = 1,
    this.shadowIntensity = 0.1,
    this.loading = Loading.eager,
    this.relatedJs,
    this.ar = false,
    this.environmentImage,
    this.defaultZoom,
    this.preferLightPreview = true,
    this.rearView = false,
  });

  final String src;
  final Color backgroundColor;
  final String? alt, cameraOrbit, relatedJs, environmentImage;
  final bool autoRotate, cameraControls, disableZoom, disablePan, ar;
  final double exposure, shadowIntensity;
  final double? defaultZoom;
  final Loading loading;
  final bool preferLightPreview;
  final bool rearView;

  @override
  State<CompatibleVehicleModel> createState() => _CompatibleVehicleModelState();
}

class _CompatibleVehicleModelState extends State<CompatibleVehicleModel> {
  Future<_ModelSource>? _source;
  int _attempt = 0;
  bool _allowHeavy = false;

  @override
  void didUpdateWidget(covariant CompatibleVehicleModel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _release(_source);
      _allowHeavy = false;
      _source = null;
    }
  }

  void _release(Future<_ModelSource>? source) {
    if (source == null) return;
    unawaited(
      source
          .then((value) => _LocalThreeServer.instance.release(value.modelUrl))
          .catchError((_) {}),
    );
  }

  @override
  void dispose() {
    _release(_source);
    super.dispose();
  }

  Future<_ModelSource> _resolve() async {
    final source = widget.src.trim();
    if (source.isEmpty) throw const FormatException('Sin modelo seleccionado');
    final viewer = await _LocalThreeServer.instance.viewerUrl();
    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      return _ModelSource(source, viewer);
    }
    if (uri?.scheme == 'file') {
      final profile = await inspectGlb(File.fromUri(uri!));
      if (profile.unsupportedExtensions.isNotEmpty)
        throw const FormatException(
          'Este GLB necesita un decodificador no disponible. Usa una foto o exporta GLB estándar/Draco.',
        );
      return _ModelSource(
        await _LocalThreeServer.instance.exposeFile(File.fromUri(uri)),
        viewer,
        profile,
      );
    }
    final file = File(source);
    if (file.isAbsolute || await file.exists()) {
      final profile = await inspectGlb(file);
      if (profile.unsupportedExtensions.isNotEmpty)
        throw const FormatException(
          'Este GLB necesita un decodificador no disponible. Usa una foto o exporta GLB estándar/Draco.',
        );
      return _ModelSource(
        await _LocalThreeServer.instance.exposeFile(file),
        viewer,
        profile,
      );
    }
    return _ModelSource(
      await _LocalThreeServer.instance.exposeAsset(source),
      viewer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (DashSettingsProvider settings) => (
        vehicle: settings.selectedVehicle,
        artwork: settings.selectedVehicle?.artworkPath,
        rearArtwork: settings.selectedVehicle?.rearArtworkPath,
        catalogUrl: settings.selectedVehicle?.modelUrl,
        lowResource: settings.isLowResourceDevice,
        reduceMotion: settings.reduceMotion,
        orbit: settings.vehicleCameraOrbit,
        zoom: settings.vehicleCameraZoom,
        color: settings.vehicleColorHex,
      ),
    );
    final rearArtwork = widget.rearView ? settings.rearArtwork : null;
    if (widget.preferLightPreview) {
      if (rearArtwork != null && rearArtwork.isNotEmpty) {
        return _VehicleLightView(artwork: rearArtwork, preview: null);
      }
      return VehicleTopView(
        colorHex: settings.color,
        vehicle: settings.vehicle,
        source: widget.src,
      );
    }
    final artwork = rearArtwork ?? settings.artwork;
    final preview =
        catalogVehiclePreview(widget.src) ??
        catalogVehiclePreview(settings.catalogUrl ?? '');
    if (widget.src.isEmpty || (rearArtwork != null && !_allowHeavy)) {
      return _VehicleLightView(
        artwork: artwork,
        preview: preview,
        onLoad3d: widget.src.isEmpty
            ? null
            : () => setState(() => _allowHeavy = true),
      );
    }
    final orbit = widget.cameraOrbit ?? settings.orbit;
    final camera = _camera(orbit, widget.defaultZoom ?? settings.zoom);
    return FutureBuilder<_ModelSource>(
      future: _source ??= _resolve(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(_friendlyError(snapshot.error));
        final source = snapshot.data;
        if (source == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (settings.lowResource &&
            source.profile?.expensive == true &&
            !_allowHeavy) {
          return _VehicleLightView(
            artwork: artwork,
            preview: preview,
            message: 'VISTA LIGERA · MODELO EXIGENTE',
            onLoad3d: () => setState(() => _allowHeavy = true),
          );
        }
        final viewer = _HybridThreeViewer(
          key: ValueKey('${source.modelUrl}-$_attempt'),
          source: source,
          backgroundColor: widget.backgroundColor,
          autoRotate:
              widget.autoRotate &&
              !settings.reduceMotion &&
              MediaQuery.maybeDisableAnimationsOf(context) != true,
          cameraControls: widget.cameraControls,
          disableZoom: widget.disableZoom,
          disablePan: widget.disablePan,
          camera: camera,
          exposure: widget.exposure,
          colorHex: settings.color,
          lowResource: settings.lowResource,
          fallbackArtwork: artwork,
          fallbackPreview: preview,
        );
        return widget.cameraControls
            ? viewer
            : IgnorePointer(ignoring: true, child: viewer);
      },
    );
  }

  _ThreeCameraConfig _camera(String orbit, double zoom) {
    final parts = orbit.trim().split(RegExp(r'\s+'));
    double angle(int index, double fallback) => index < parts.length
        ? double.tryParse(parts[index].replaceAll('deg', '')) ?? fallback
        : fallback;
    var distance = 5.0;
    if (parts.length > 2 && parts[2].endsWith('m')) {
      distance =
          double.tryParse(parts[2].substring(0, parts[2].length - 1)) ?? 5;
    }
    return _ThreeCameraConfig(
      azimuth: angle(0, 0),
      polar: angle(1, 75),
      distanceFactor: ((distance / max(zoom, .1)) / 3).clamp(.65, 6),
    );
  }

  String _friendlyError(Object? error) {
    final value = error.toString();
    if (error is FormatException) return error.message;
    if (value.contains('no existe')) {
      return 'El modelo 3D debe descargarse nuevamente.';
    }
    if (value.contains('GLB válido') || value.contains('incompleto')) {
      return 'El modelo descargado está dañado. Descárgalo nuevamente.';
    }
    return 'No se pudo preparar el visor 3D.';
  }

  Widget _error(String message) => _ThreeError(
    message: message,
    onRetry: () => setState(() {
      _attempt++;
      _release(_source);
      _source = _resolve();
    }),
  );
}

class _ThreeCameraConfig {
  const _ThreeCameraConfig({
    required this.azimuth,
    required this.polar,
    required this.distanceFactor,
  });
  final double azimuth, polar, distanceFactor;

  @override
  String toString() => '$azimuth/$polar/$distanceFactor';
}

class _HybridThreeViewer extends StatefulWidget {
  const _HybridThreeViewer({
    super.key,
    required this.source,
    required this.backgroundColor,
    required this.autoRotate,
    required this.cameraControls,
    required this.disableZoom,
    required this.disablePan,
    required this.camera,
    required this.exposure,
    required this.colorHex,
    required this.lowResource,
    this.fallbackArtwork,
    this.fallbackPreview,
  });

  final _ModelSource source;
  final Color backgroundColor;
  final bool autoRotate, cameraControls, disableZoom, disablePan, lowResource;
  final _ThreeCameraConfig camera;
  final double exposure;
  final String colorHex;
  final String? fallbackArtwork;
  final String? fallbackPreview;

  @override
  State<_HybridThreeViewer> createState() => _HybridThreeViewerState();
}

class _HybridThreeViewerState extends State<_HybridThreeViewer> {
  late final WebViewController _controller;
  String? _error;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    _loadTimeout = Timer(const Duration(seconds: 25), () {
      _showError('El radio no pudo cargar el modelo 3D.');
    });
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..addJavaScriptChannel(
        'Dashcore3d',
        onMessageReceived: (message) {
          Map<String, dynamic> event;
          try {
            event = jsonDecode(message.message) as Map<String, dynamic>;
          } catch (_) {
            return;
          }
          if (event['type'] == 'ready') _loadTimeout?.cancel();
          if (event['type'] == 'error' || event['type'] == 'loadError') {
            _showError('Este modelo no pudo abrirse en el radio.');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _initializeViewer(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              _showError('No se pudo iniciar el visor 3D.');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.source.viewerUrl));
  }

  void _showError(String message) {
    if (!mounted) return;
    _loadTimeout?.cancel();
    setState(() => _error = message);
    unawaited(
      _controller
          .runJavaScript(
            'if(window.disposeDashcore){window.disposeDashcore();}',
          )
          .catchError((_) {}),
    );
  }

  @override
  void didUpdateWidget(covariant _HybridThreeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.colorHex != widget.colorHex) {
      final color = jsonEncode(widget.colorHex);
      unawaited(
        _controller
            .runJavaScript(
              'if(window.updateDashcoreColor){window.updateDashcoreColor($color);}',
            )
            .catchError((_) {}),
      );
    }
    if (oldWidget.camera.toString() != widget.camera.toString()) {
      final camera = jsonEncode({
        'azimuth': widget.camera.azimuth,
        'polar': widget.camera.polar,
        'distanceFactor': widget.camera.distanceFactor,
      });
      unawaited(
        _controller
            .runJavaScript(
              'if(window.updateDashcoreCamera){window.updateDashcoreCamera($camera);}',
            )
            .catchError((_) {}),
      );
    }
    if (oldWidget.autoRotate != widget.autoRotate) {
      unawaited(
        _controller
            .runJavaScript(
              'if(window.updateDashcoreMotion){window.updateDashcoreMotion(${widget.autoRotate});}',
            )
            .catchError((_) {}),
      );
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    unawaited(
      _controller
          .runJavaScript(
            'if(window.disposeDashcore){window.disposeDashcore();}',
          )
          .catchError((_) {}),
    );
    super.dispose();
  }

  Future<void> _initializeViewer() async {
    final config = jsonEncode({
      'src': widget.source.modelUrl,
      'autoRotate': widget.autoRotate,
      'cameraControls': widget.cameraControls,
      'disableZoom': widget.disableZoom,
      'disablePan': widget.disablePan,
      'lowResource': widget.lowResource,
      'azimuth': widget.camera.azimuth,
      'polar': widget.camera.polar,
      'distanceFactor': widget.camera.distanceFactor,
      'exposure': widget.exposure,
      'color': widget.colorHex,
    });
    try {
      await _controller.runJavaScript('window.initDashcore($config);');
    } catch (_) {
      _showError('No se pudo iniciar el visor 3D.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return _VehicleLightView(
        artwork: widget.fallbackArtwork,
        preview: widget.fallbackPreview,
        message: 'VISTA LIGERA · 3D NO DISPONIBLE',
        onLoad3d: () {
          setState(() => _error = null);
          _loadTimeout = Timer(
            const Duration(seconds: 25),
            () => _showError('El modelo no respondió.'),
          );
          unawaited(
            _controller.reload().catchError(
              (_) => _showError('No se pudo reiniciar el visor.'),
            ),
          );
        },
      );
    return WebViewWidget(controller: _controller);
  }
}

class _VehicleLightView extends StatelessWidget {
  const _VehicleLightView({
    this.artwork,
    this.preview,
    this.onLoad3d,
    this.message = 'VISTA LIGERA',
  });
  final String? artwork;
  final String? preview;
  final VoidCallback? onLoad3d;
  final String message;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      fit: StackFit.expand,
      children: [
        if (artwork != null)
          Image.file(
            File(artwork!),
            fit: BoxFit.contain,
            cacheWidth: 520,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.directions_car_filled_rounded,
              size: 100,
              color: Color(0xFF4E91AD),
            ),
          )
        else if (preview != null)
          Image.asset(preview!, fit: BoxFit.contain, cacheWidth: 520)
        else
          const Center(
            child: Icon(
              Icons.directions_car_filled_rounded,
              size: 100,
              color: Color(0xFF4E91AD),
            ),
          ),
        if (constraints.maxHeight >= 90)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                if (onLoad3d != null)
                  TextButton(
                    onPressed: onLoad3d,
                    child: const Text('CARGAR 3D'),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

String? catalogVehiclePreview(String source) {
  final uri = Uri.tryParse(source.replaceAll('\\', '/'));
  final file = uri?.pathSegments.lastOrNull?.toLowerCase();
  final name = switch (file) {
    'honda_civic_16_lite.glb' => 'Honda_Civic_16',
    'kia_optima_15_lite.glb' => 'Kia_Optima_15',
    'nissan_h1_lite.glb' => 'nissan_h1',
    'optima2012_lite.glb' => 'OPTIMA2012',
    'sonata_nrise_lite.glb' => 'Sonata_nrise',
    'sonata_y20_lite.glb' => 'Sonata_y20',
    'sonatalf_lite.glb' => 'Sonatalf',
    _ => null,
  };
  return name == null ? null : 'assets/images/png/vehicle_previews/$name.png';
}

class _ThreeError extends StatelessWidget {
  const _ThreeError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.view_in_ar_rounded, color: Colors.white54, size: 38),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          TextButton(onPressed: onRetry, child: const Text('REINTENTAR')),
        ],
      ),
    ),
  );
}

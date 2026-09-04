import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_hub.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../providers/obd_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/dash_settings_provider.dart';
import '../../models/obd_data.dart';
import '../dashboard_background.dart';

class PremiumDashboard extends StatefulWidget {
  final ObdData data;
  final double fuelLevel;

  const PremiumDashboard({super.key, required this.data, required this.fuelLevel});
  @override State<PremiumDashboard> createState() => _PremiumDashboardState();
}

class _PremiumDashboardState extends State<PremiumDashboard> {
  bool _isYoutubeMode = true;
  WebViewController? _webController;
  VideoPlayerController? _localController;
  List<String> _videoPaths = [];
  int _currentVideoIndex = -1;
  bool _isFullScreen = false;
  bool _hasWebError = false;
  String _currentVideoId = 'https://www.youtube.com/@DashcoreTeam'; // Default channel URL

  final RegExp _youtubeIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadPlaylist();
  }

  void _initWebView() {
    String finalUrl;
    if (_youtubeIdRegex.hasMatch(_currentVideoId)) {
      finalUrl = 'https://www.youtube.com/embed/$_currentVideoId?autoplay=1&modestbranding=1&rel=0&controls=1';
    } else if (_currentVideoId.startsWith('http')) {
      finalUrl = _currentVideoId;
    } else {
      debugPrint('⚠️ Invalid YouTube reference: $_currentVideoId');
      _hasWebError = true;
      return;
    }

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (mounted) setState(() => _hasWebError = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
  }

  void _openInYoutube() async {
    Uri url;
    if (_youtubeIdRegex.hasMatch(_currentVideoId)) {
      url = Uri.parse('https://www.youtube.com/watch?v=$_currentVideoId');
    } else if (_currentVideoId.startsWith('http')) {
      url = Uri.parse(_currentVideoId);
    } else {
      return;
    }

    if (await url_launcher.launchUrl(url, mode: url_launcher.LaunchMode.externalApplication)) {
      // Success
    }
  }

  Future<void> _loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('premium_playlist') ?? [];
    final List<String> existing = [];
    for (final p in paths) { if (await File(p).exists()) existing.add(p); }
    if (mounted) { setState(() { _videoPaths = existing; if (_videoPaths.isNotEmpty) _playLocalVideo(0); }); }
  }

  void _playLocalVideo(int index) {
    if (index < 0 || index >= _videoPaths.length) return;
    setState(() {
      _currentVideoIndex = index;
      _localController?.dispose();
      _localController = VideoPlayerController.file(File(_videoPaths[index]))..initialize().then((_) { if (mounted) { setState(() {}); _localController?.play(); _localController?.setLooping(true); } });
    });
  }

  @override
  void dispose() {
    _localController?.dispose();
    _webController?.loadRequest(Uri.parse('about:blank')); // Clear memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final accentColor = settings.accentColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (settings.backgroundImage != null && settings.backgroundImage != 'COLOR_BLACK')
            Positioned.fill(child: DashboardBackground(backgroundImage: settings.backgroundImage, isAssetBackground: settings.isAssetBackground, opacity: 0.2)),

          Row(
            children: [
              if (!_isFullScreen)
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Expanded(flex: 6, child: _buildSpeedometer(accentColor)),
                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_miniInfo(Icons.bolt_rounded, '${widget.data.voltage.toStringAsFixed(1)}V', 'VOLT', accentColor), _miniInfo(Icons.thermostat_rounded, '${widget.data.engineTemp}°C', 'TEMP', accentColor), _miniInfo(Icons.local_gas_station_rounded, '${widget.fuelLevel.round()}%', 'FUEL', accentColor)]),
                        const Spacer(),
                        MusicHub(accentColor: accentColor, width: 300),
                      ],
                    ),
                  ),
                ),

              Expanded(
                flex: 6,
                child: Container(
                  margin: _isFullScreen ? EdgeInsets.zero : const EdgeInsets.fromLTRB(0, 10, 10, 10),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 20), border: _isFullScreen ? null : Border.all(color: Colors.white10)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 20),
                    child: Column(
                      children: [
                        Expanded(
                          child: _isYoutubeMode
                            ? (_hasWebError
                                ? _buildWebErrorFallback(accentColor)
                                : WebViewWidget(controller: _webController!))
                            : _buildLocalPlayerArea(accentColor)
                        ),
                        _buildVideoControls(settings, accentColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebErrorFallback(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white24, size: 40),
          const SizedBox(height: 10),
          const Text('VIDEO NO DISPONIBLE EN MODO EMBED', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _openInYoutube,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('ABRIR EN YOUTUBE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPlayerArea(Color accent) {
    return _localController != null && _localController!.value.isInitialized
        ? Center(child: AspectRatio(aspectRatio: _localController!.value.aspectRatio, child: VideoPlayer(_localController!)))
        : Center(child: Icon(Icons.video_library_rounded, size: 60, color: Colors.white12));
  }

  Widget _buildVideoControls(DashSettingsProvider settings, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isYoutubeMode ? Icons.refresh_rounded : (_localController?.value.isPlaying ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded), color: Colors.white, size: 18),
            onPressed: () {
              if (_isYoutubeMode) {
                setState(() => _hasWebError = false);
                _webController?.reload();
              } else {
                setState(() {
                  if (_localController?.value.isPlaying ?? false) _localController?.pause();
                  else _localController?.play();
                });
              }
            }
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              _isYoutubeMode = !_isYoutubeMode;
              if (_isYoutubeMode) {
                _localController?.pause();
                if (_youtubeIdRegex.hasMatch(_currentVideoId)) {
                  _webController?.loadRequest(Uri.parse('https://www.youtube.com/embed/$_currentVideoId?autoplay=1&modestbranding=1&rel=0&controls=1'));
                } else {
                  _hasWebError = true;
                }
              } else {
                _webController?.loadRequest(Uri.parse('about:blank'));
              }
            }),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(_isYoutubeMode ? 'YOUTUBE' : 'LOCAL', style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.bold))),
          ),
          IconButton(icon: Icon(_isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white38, size: 18), onPressed: () => setState(() => _isFullScreen = !_isFullScreen)),
        ],
      ),
    );
  }

  Widget _buildSpeedometer(Color accent) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${widget.data.speed}', style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.w900, height: 1)), Text('KM/H', style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4))]));
  Widget _miniInfo(IconData i, String v, String l, Color a) => Column(children: [Icon(i, color: Colors.white24, size: 22), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)), Text(l, style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold))]);
}

class _PremiumMusicHub extends StatelessWidget {
  final double maxWidth;
  const _PremiumMusicHub({required this.maxWidth});
  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.music_note_rounded, color: Color(0xFF00E5FF), size: 16), const SizedBox(width: 8), Expanded(child: Text(music.trackTitle, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))), IconButton(onPressed: music.playPause, icon: Icon(music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20))]));
  }
}

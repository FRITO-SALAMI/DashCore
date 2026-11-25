import '../core/backend_config.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/dash_settings_provider.dart';
import '../services/supabase_service.dart';
import '../widget/empty_state_widget.dart';
import 'auth_screen.dart';

class DashLeagueScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DashLeagueScreen({super.key, required this.onBack});

  @override
  State<DashLeagueScreen> createState() => _DashLeagueScreenState();
}

class _DashLeagueScreenState extends State<DashLeagueScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  String? _myRemoteAvatar;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final settings = context.read<DashSettingsProvider>();

      // Intentar sincronizar datos propios primero para asegurar presencia en el ranking
      await settings.syncProfileToSupabase();

      final response = await SupabaseService.instance.getDashLeagueRanking();
      final myProfile = await SupabaseService.instance.getMyProfile();

      if (mounted) {
        setState(() {
          _leaderboard = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
          _loadFailed = false;
          _myRemoteAvatar = myProfile?['avatar_url']?.toString();
        });
        debugPrint('DashLeague: Loaded ${_leaderboard.length} users');
      }
    } catch (e) {
      debugPrint('DashLeague: Error fetching leaderboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final user = SupabaseService.instance.currentUser;
    final isSpanish = settings.language == Language.spanish;

    final String displayName =
        user?.userMetadata?['display_name'] ??
        user?.email?.split('@')[0] ??
        'CONDUCTOR';

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'DASHLEAGUE 🔥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildProfileCard(displayName, settings),
                  const SizedBox(height: 25),
                  Text(
                    isSpanish
                        ? 'CLASIFICACIÓN GLOBAL (TOP 50)'
                        : 'GLOBAL RANKING (TOP 50)',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    )
                  else if (_loadFailed)
                    EmptyStateWidget(
                      icon: Icons.cloud_off_rounded,
                      title: isSpanish ? 'SIN CONEXIÓN' : 'CONNECTION ERROR',
                      description: isSpanish
                          ? 'No se pudo cargar la clasificación. Inténtalo nuevamente.'
                          : 'The ranking could not be loaded. Please try again.',
                    )
                  else if (user == null)
                    EmptyStateWidget(
                      icon: Icons.login_rounded,
                      title: isSpanish
                          ? 'INICIA SESIÓN PARA COMPETIR'
                          : 'SIGN IN TO COMPETE',
                      description: isSpanish
                          ? 'Crea tu perfil y aparece en la clasificación global.'
                          : 'Create your profile and join the global ranking.',
                      actionLabel: isSpanish ? 'INICIAR SESIÓN' : 'SIGN IN',
                      onAction: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                        if (mounted) _fetchLeaderboard();
                      },
                    )
                  else if (_leaderboard.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.emoji_events_outlined,
                      title: isSpanish ? 'LIGA VACÍA' : 'EMPTY LEAGUE',
                      description: isSpanish
                          ? 'Aún no hay competidores. ¡Sé el primero!'
                          : 'There are no competitors yet. Be the first!',
                    )
                  else
                    ...List.generate(_leaderboard.length, (index) {
                      final item = _leaderboard[index];
                      String uName = item['username']?.toString() ?? 'PILOTO';
                      if (uName.trim().isEmpty) uName = 'PILOTO';
                      if (uName.length > 15) {
                        uName = '${uName.substring(0, 12)}...';
                      }

                      final bool isMe = item['is_me'] == true;
                      final rank =
                          (item['position'] as num?)?.toInt() ?? index + 1;

                      return _buildLeaderboardItem(
                        rank,
                        uName,
                        '${(item['total_distance'] ?? 0).round()} KM',
                        '${(item['max_speed'] ?? 0).round()} KM/H',
                        isMe,
                        item['avatar_url']?.toString(),
                        isSpanish,
                        item['ranking_key']?.toString(),
                        item,
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, DashSettingsProvider settings) {
    final isSpanish = settings.language == Language.spanish;
    final metadataAvatar = SupabaseService
        .instance
        .currentUser
        ?.userMetadata?['avatar_url']
        ?.toString();
    final remoteAvatar = _myRemoteAvatar ?? metadataAvatar;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF13161D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.1),
            backgroundImage: settings.profileImageUrl != null
                ? FileImage(File(settings.profileImageUrl!))
                : (remoteAvatar != null ? NetworkImage(remoteAvatar) : null),
            child: settings.profileImageUrl == null && remoteAvatar == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 35,
                    color: Color(0xFF00E5FF),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  settings.driverLevel.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCompact(
                      'KM',
                      '${settings.totalDistance.round()}',
                    ),
                    const SizedBox(width: 15),
                    _buildStatCompact('MAX', '${settings.maxSpeed.round()}'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isSpanish ? 'Compartir DashCore' : 'Share DashCore',
            onPressed: () => Share.share(
              isSpanish
                  ? 'Estoy compitiendo en DashLeague con DashCore, el tablero inteligente para tu vehículo. Descarga DashCore aquí: https://dashcore-web.vercel.app/'
                  : 'I am competing in DashLeague with DashCore, the smart dashboard for your vehicle. Download DashCore: https://dashcore-web.vercel.app/',
              subject: 'DashCore · DashLeague',
            ),
            icon: const Icon(Icons.share_rounded, color: Color(0xFF00E5FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCompact(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
    int rank,
    String name,
    String km,
    String speed,
    bool isMe,
    String? avatarUrl,
    bool isSpanish,
    String? rankingKey,
    Map<String, dynamic> profile,
  ) {
    return InkWell(
      key: rankingKey == null ? null : ValueKey(rankingKey),
      onTap: () => _showPublicProfile(context, profile, rank, isSpanish),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: isMe
              ? Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontSize: isMe ? 16 : 14,
              ),
            ),
            const SizedBox(width: 20),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? (avatarUrl.startsWith('http')
                        ? NetworkImage(avatarUrl)
                        : NetworkImage(
                            '${BackendConfig.storageUrl}/avatars/$avatarUrl',
                          ))
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: Color(0xFF00E5FF),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name + (isMe ? (isSpanish ? ' (TÚ)' : ' (YOU)') : ''),
                style: TextStyle(
                  color: isMe ? const Color(0xFF00E5FF) : Colors.white,
                  fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  km,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.normal,
                  ),
                ),
                Text(
                  speed,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white30,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showPublicProfile(
    BuildContext context,
    Map<String, dynamic> profile,
    int rank,
    bool isSpanish,
  ) {
    String text(String key, [String fallback = '—']) {
      final value = profile[key]?.toString().trim();
      return value == null || value.isEmpty ? fallback : value;
    }

    final username = text('username', isSpanish ? 'PILOTO' : 'DRIVER');
    final publicName = text('full_name', username);
    final country = _countryName(text('country_code'), isSpanish);
    final distance = (profile['total_distance'] as num?)?.round() ?? 0;
    final maxSpeed = (profile['max_speed'] as num?)?.round() ?? 0;
    final avatarUrl = profile['avatar_url']?.toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111720),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: const Color(0xFF00E5FF).withValues(alpha: .1),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(_avatarUrl(avatarUrl))
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded, size: 42)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                publicName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '@$username · $country',
                style: const TextStyle(color: Color(0xFF00E5FF)),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _publicStat(
                      '#$rank',
                      isSpanish ? 'POSICIÓN' : 'RANK',
                    ),
                  ),
                  Expanded(
                    child: _publicStat(
                      '$distance KM',
                      isSpanish ? 'DISTANCIA' : 'DISTANCE',
                    ),
                  ),
                  Expanded(
                    child: _publicStat(
                      '$maxSpeed KM/H',
                      isSpanish ? 'VELOCIDAD MÁX.' : 'MAX SPEED',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _publicStat(String value, String label) => Column(
    children: [
      Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38, fontSize: 9),
      ),
    ],
  );

  String _avatarUrl(String value) => value.startsWith('http')
      ? value
      : '${BackendConfig.storageUrl}/avatars/$value';

  String _countryName(String code, bool isSpanish) {
    const spanish = {
      'DO': 'República Dominicana',
      'US': 'Estados Unidos',
      'MX': 'México',
      'CO': 'Colombia',
      'ES': 'España',
      'PR': 'Puerto Rico',
    };
    const english = {
      'DO': 'Dominican Republic',
      'US': 'United States',
      'MX': 'Mexico',
      'CO': 'Colombia',
      'ES': 'Spain',
      'PR': 'Puerto Rico',
    };
    return (isSpanish ? spanish : english)[code.toUpperCase()] ?? code;
  }
}
